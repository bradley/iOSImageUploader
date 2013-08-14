class PhotosController < ApplicationController

  def index
    @photos = Photo.order("created_at DESC")
    render :json => @photos
  end

  def create
    @photo = Photo.new(params[:photo])
    if @photo.save
      render :json => {
        :success => true,
        :photos => @photo
      }
    else
      render :json => {
        :success => false,
        :errors => @photos.error
      }
    end
  end
end
