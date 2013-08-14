Image Uploader
===========

This project includes a client and server example.

##Setting up the server

The Rails server uses Carrierwave to upload images to an Amazon Web 
Services S3 Bucket. I will leave the setting up of this bucket to you 
(sorry) but once you've done so, you just need to create a carrierwave.rb
file in your /config/initializers directory (see the example there) and
fill in the relevant credentials. 

##Setting up the client

There isn't a whole lot that needs to be done on the client app, but you will
need to update the BASE_URL constant in DLAPIClient.m

To put it briefly, you cannot run the camera on the simulator and therefore
need to run this project on your testing device. In order for the app to 
connect with the server -- which is likely running on localhost -- you 
need to tell the project that the BASE_URL is your ip address.

Follow these steps:

1. In your terminal (Mac), type 'ifconfig' to find your IP address.

2. In the client project, find DLAPIClient.m and replace the words
'localhost' in the BASE_URL client with your IP address. It should look
something like this:

```
#define BASE_URL @"http://<your IP address>:9292"
```

3. On your device, connect to your local wifi. This is important. Your 
app will not be able to connect to your server running locally unless
the two are on the same wifi network.

##Running the app

If all goes well, you should be able to navigate to the server directory
and type:

```
bundle exec rackup
```

This will start the application server. Now, if you run the app on your
device, you should be able to snap a photo and upload it. If the upload 
succeeds, the camera view will dismiss itself.

To see the URL for your photo online, pop open the rails console and type:

```
Photo.last.image
```


##About the camera

I have the camera view arranged to provide a nice, clean interface for 
taking *square* images.

If you tap once on the preview area (showing the live camera feed) a ring 
will appear. A single tap focuses the camera on the tapped point.

If you tap twice on the preview area, the same ring will appear, but this 
time the camera will also adjust its white balance. 

The two interaction elements described above allow a user to set the white
balance dependant on one area, while focusing on another. Play around with
it to see why I thought this was a nice feature (that can easily be removed). 

