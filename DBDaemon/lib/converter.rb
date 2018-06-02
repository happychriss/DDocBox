require_relative '../lib/support'

class Converter


  PAGE_SOURCE_SCANNED=0
  PAGE_SOURCE_UPLOADED=1
  PAGE_SOURCE_MOBILE=2
  PAGE_SOURCE_MIGRATED=99


  include Support

  def initialize(web_server_uri,options)
    @web_server_uri=web_server_uri
    @ocr_abby_available=linux_program_exists?('abbyyocr')
    @ocr_tesseract_available=linux_program_exists?('tesseract')
    puts "********* Init Converter with: #{@web_server_uri} / Abby-OCR:#{@ocr_abby_available} / Tesseract-OCR:#{@ocr_tesseract_available}*******"
    @unpaper_speed=options[:unpaper_speed]=='y'
  end


  ################## Called from DRB ###################################################

  def run_conversion(data_jpg, mime_type, source, page_id)


    begin
      t=Thread.new do

        begin
          convert_data(data_jpg, mime_type, source, page_id)
        rescue => e
          puts "************ ERROR *****: #{e.message}"
          converter_status_update("ERROR:#{e.message}")
          raise
        end

      end

      t.abort_on_exception = true
    end

  end


  ################ Do all the work #########################

  def convert_data(data_jpg, mime_type, source, page_id)

    begin

      f_org = Tempfile.new("cd2_remote")
      f_org.write(data_jpg)
      f_org.untaint #avoid ruby insecure operation: http://stackoverflow.com/questions/12165664/what-are-the-rubys-objecttaint-and-objecttrust-methods
      fpath=f_org.path #full path to the file to be processed

      puts "********* Start operation Page:#{page_id} / mime_type: #{mime_type.to_s} / source: #{source.to_s} and tempfile #{fpath} in folder #{Dir.pwd}*************"

      converter_status_update("-")

      result_txt=''
      result_sjpg=nil
      result_jpg=nil

      ############################################################## PDF File ###############################################
      ### create preview images, scan pdf for text

      if [:PDF].include?(mime_type)


        check_program('convert')
        puts "------------ Start pdf convertion: Source: '#{fpath}' Target: '#{fpath+'.conv'}'----------"

        result_sjpg = convert_sjpg(fpath)
        result_jpg = convert_jpg(fpath)

        converter_upload_jpgs(result_jpg, result_sjpg, page_id)


        ## only abby OCD supports PDF as input for OCR
        if @ocr_abby_available then

          check_program('abbyyocr')
          converter_status_update("PDF-Abby")

          command="abbyyocr -fm -rl German GermanNewSpelling  -if '#{fpath}' -tet UTF8 -of '#{fpath}.conv.txt'"
          res = %x[#{command}]

          result_txt = read_txt_from_conv_txt(fpath.untaint)

          converter_upload_pdf(result_txt,File.open(fpath), page_id)

        end


        ############################################################## JPG File ###############################################
        ### Source is Scanner / Upload from Mobile / Upload from PC

      elsif [:JPG].include?(mime_type) then

        check_program('convert'); check_program('pdftotext'); check_program('unpaper');check_program('gs')
        puts "------------ Start conversion for jpg: Source: '#{fpath}' Target: '#{fpath+'.conv'}'----------"

        #### Run additional unpaper from orignal file, if not the speed option is selected
        if source==PAGE_SOURCE_SCANNED  and not @unpaper_speed
          puts "Source: Scanner without speed option - run additional unpaper..."
          res=%x[convert '#{fpath}'[0] '#{fpath}.ppm'] #convert only first page if more exists
          %x[unpaper -v --overwrite  --mask-scan-size 120 --post-size a4 --sheet-size a4 --no-grayfilter --no-blackfilter  --pre-border 0,200,0,0 '#{fpath}.ppm' '#{fpath}.unpaper']
          %x[convert '#{fpath}.unpaper' jpg:'#{fpath}']
        end

        fopath=fpath+'.orient'
        res=%x[convert '#{fpath}'[0] -auto-orient jpg:'#{fopath}'] #convert only first page if more exists

        result_sjpg = convert_sjpg(fopath)
        result_jpg = convert_jpg(fopath)
        converter_upload_jpgs(result_jpg, result_sjpg, page_id)

        #### Use Abby if available ###########################
        if @ocr_abby_available then

          check_program('abbyyocr')
          converter_status_update("JPG-Abby")

          ## pfq 20, reduce quality to 20% if from scanner
          ## Update after upgrade to Ubuntu 16.04, abbyocr create bad jpg PDF when started with -pfq 2ß, therefore change to pfpr orignal

          if source==PAGE_SOURCE_SCANNED or source==PAGE_SOURCE_MOBILE then #Source is scanner, reduce size
#            reduce='-pfq 20'
            reduce='-pfpr original'
            puts "Source is scanner or mobile, reduction with: #{reduce} - will be stored as PDF"
            command="abbyyocr -rl German GermanNewSpelling  -if '#{fopath}' -f PDF -pem ImageOnText #{reduce} -of '#{fpath}.big.conv'"
            res = %x[#{command}]

            ## change size to normal a4
            command="gs -o '#{fpath}.conv' -sDEVICE=pdfwrite  -dPDFFitPage -r300x300  -g2480x3508  '#{fpath}.big.conv'"
            res = %x[#{command}]
          else
            reduce='-pfpr original'
            puts "Source is not scanner, dont reduce jpg with: #{reduce} - will be stored as JPG"

            command="abbyyocr -rl German GermanNewSpelling  -if '#{fopath}' -f PDF -pem ImageOnText #{reduce} -of '#{fpath}.conv'"
            res = %x[#{command}]
          end

          #### Use Abby if available ###########################
        elsif @ocr_tesseract_available then

          check_program('tesseract')
          converter_status_update("JPG-Tesser")

          ## create outputfile with fixed name xxxx.conf.pdf - must be renamed
          command="tesseract -l deu '#{fpath}' '#{fpath}.conv' pdf"
          res = %x[#{command}]

          command="mv '#{fpath}.conv.pdf' '#{fpath}.conv'"
          res = %x[#{command}]
        end

        if @ocr_tesseract_available or @ocr_abby_available



          if source==PAGE_SOURCE_UPLOADED
            puts "Return normal JPG - Uploaded"
            result_new_pdf=File.open(fpath) # uploaded jpg file will not be stored as converted PFD
          else
            puts "Return normal Converted PDF"
            result_new_pdf=File.open(fpath+'.conv') ## PDF return
          end


          puts "ok with res: #{res}"

          puts "Start pdftotxt..."
          ## Extract text data and store in database
          res=%x[pdftotext -layout '#{fpath+'.conv'}' #{fpath+'.conv.txt'}]
          result_txt = read_txt_from_conv_txt(fpath)
          converter_upload_pdf(result_txt,result_new_pdf, page_id)

        end

############################################################## JPG File ###############################################

      elsif [:MS_EXCEL, :MS_WORD, :ODF_CALC, :ODF_WRITER].include?(mime_type) then

        tika_path=File.join(Dir.pwd, "lib", "tika-app-1.4.jar")

        check_program('convert'); check_program('html2ps');# check_program(tika_path) ##jar can be called directly

        ############### Create Preview Pictures of uploaded file

        puts "------------ V2 Start conversion for pdf or jpg: Source: '#{fpath}' ----------"

        ## Tika ############################### http://tika.apache.org/

        command="java -jar #{tika_path} -h '#{fpath}' >> #{fpath+'.conv.html'}"

	puts "Starting with command:"
	puts command

        res=%x[#{command}]
        puts "ok, Result: #{res}"


        converter_status_update("Office-Tika")
        res=%x[convert '#{fpath+'.conv.html'}'[0] jpg:'#{fpath+'.conv.tmp'}'] #convert only first page if more exists


        result_sjpg = convert_sjpg(fpath, '.conv.tmp')
        result_jpg = convert_jpg(fpath, '.conv.tmp')

        converter_upload_jpgs(result_jpg, result_sjpg, page_id)

        ################ Extract Test from uploaded file

        puts "Start tika to extract text V2..."
        res=%x[java -jar #{tika_path} -t '#{fpath}' >> #{fpath+'.conv.txt'}]

        result_txt = read_txt_from_conv_txt(fpath)
        converter_upload_pdf(result_txt, File.open(fpath), page_id)

      else
        raise "Unkonw mime -type  *#{mime_type}*"
      end

      puts "Clean-up with: #{fpath+'*'}..."
      #### Cleanup and return
      Dir.glob(fpath+'*').each do |l|
        l.untaint
        File.delete(l)
      end
      puts "ok"
      puts "--------- Completed and  file deleted------------"

    rescue Exception => e
      puts "Error:"+ e.message
      return nil, nil, nil, nil, "Error:"+ e.message
    end
  end

  def read_txt_from_conv_txt(fpath)
    puts "    start reading textfile"
    result_txt=''
    File.open(fpath+'.conv.txt', 'r') { |l| result_txt=l.read }
    puts "ok"
    return result_txt
  end

  def convert_jpg(fpath, source_extension='')
    puts "Start converting to jpg..."
    res=%x[convert '#{fpath+source_extension}'[0]   -flatten -resize x770 jpg:'#{fpath+'.conv.jpg'}'] #convert only first page if more exists
    result_jpg=File.open(fpath+'.conv.jpg')
    puts "ok"
    result_jpg
  end

  def convert_sjpg(fpath, source_extension='')
    puts "Start converting to sjpg..."
    res=%x[convert '#{fpath+source_extension}'[0]  -flatten -resize 350x490\! jpg:'#{fpath+'.conv.sjpg'}'] #convert only first page if more exists
    result_sjpg=File.open(fpath+'.conv.sjpg')
    puts "ok"
    result_sjpg
  end


  ##################################### Upload back to server when completed

  def converter_upload_jpgs(result_jpg, result_sjpg, page_id)
    puts "*** Upload JPGS to #{@web_server_uri} via convert_upload_jpgs"
    RestClient.post @web_server_uri+'/convert_upload_jpgs', {:page => {:result_sjpg => result_sjpg, :result_jpg => result_jpg, :id => page_id}}, :content_type => :json, :accept => :json
  end

  def converter_upload_pdf(text,pdf_data,page_id)
    puts "*** Upload text from PDF to #{@web_server_uri} via convert_upload_pdf"
    RestClient.post @web_server_uri+'/convert_upload_pdf', {:page => {:content => text,:pdf_data => pdf_data, :id => page_id}}, :content_type => :json, :accept => :json
    converter_status_update("ok")
  end


  ##################################### Update Status

  def converter_status_update(message)
    puts "DRBCONVERTER: #{message}"
    RestClient.post @web_server_uri+'/convert_status', {:message => message}, :content_type => :json, :accept => :json
  end


    private :read_txt_from_conv_txt, :convert_jpg, :convert_sjpg, :converter_status_update, :converter_upload_jpgs, :converter_upload_pdf
end
