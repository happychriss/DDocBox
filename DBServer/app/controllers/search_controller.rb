
class SearchController < ApplicationController

  def search
    @current_keywords||= []
    @sort_mode||= :time
  end

  def found

    session[:search_results] = request.url
    session[:sort_mode]=params[:sort_mode]
    @sort_mode=params[:sort_mode].to_sym

    @current_keywords=params[:document].nil? ? []:params[:document][:keyword_list]

    @pages_new_document=Page.new_document_pages ##pages that have been assigned a new document (remove action in document.edit)
    @pages=Page.search_index(params[:q],@current_keywords, params[:page],@pages_new_document,@sort_mode)

    @q=params[:q]


    render :action => 'search'

end

  ## add a page to the document via drag and drop (from search screen)
  def add_page
    drag_id=params[:drag_id][/\d+/].to_i
    drop_id=params[:drop_id][/\d+/].to_i #I get the new page

    @drag_page=Page.find(drag_id)
    @drop_page=Page.find(drop_id)

    @drag_page.add_to_document(@drop_page.document)
    @drop_page.reload
  end

  ### Show document PDF and RTF

  def show_rtf
    @page=Page.find(params[:id])
  end

  def show_jpg_page
    page=Page.find(params[:id])
    jpg=page.jpg_file
    send_file(jpg.path, :type => 'application/jpg', :page => '1')
    jpg.close
    return
  end

  def show_pdf_document
    document=Document.find(params[:id])
    pdf=document.pdf_file
    send_file(pdf.path, :type => 'application/pdf', :page => '1')
    pdf.close
    return
  end

  def show_original
    @page=Page.find(params[:id])

    data=File.read(@page.path(:org))
    send_data( data, :filename => @page.original_filename,:type => @page.mime_type, :page => '1' )

    return
  end

  def show_document_pages
    @pages=Document.find(params[:id]).pages.limit(4)
  end

end



