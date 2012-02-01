class DirectoriesController < ApplicationController

  respond_to :json

  def clicks
    @directories = Directory.includes(:files).where(:name => params[:directories])
    @clicks = []
    @directories.each do |directory|
      html, jpeg = 0, 0
      directory.files.each { |file| file.click ? html += 1 : jpeg +=1 }
      @clicks << {name: directory.name, jpeg_clicks: jpeg, html_clicks: html}
    end
    respond_with(@clicks)
  end

end
