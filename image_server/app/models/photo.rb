class Photo < ActiveRecord::Base
	attr_accessible :image

	mount_uploader :image, PhotoUploader
end