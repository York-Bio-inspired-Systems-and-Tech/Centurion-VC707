#include <stdlib.h>
#include <stdio.h>
#include "centurion_lib.h"

//openCV libraries
#include <opencv2/opencv.hpp>
#include <opencv2/imgcodecs.hpp>
#include <highgui.h>

using namespace cv;

int main(int argc, char **argv)
{

	Centurion_Lib_init();
	//reset the NoC
	Centurion_Reset_NoC();

	printf("Opening the video source\n");

	 Mat image_in;
image_in = imread("/home/mr589/ant.jpg", 1 );
	 //image_in = imread("/home/mr589/test_img.png", IMREAD_COLOR);

	  if(!image_in.data )
	    {
	      printf( "No image data \n" );
	      return -1;
	    }
	  //check if image data is contigous (no gap between row data). Recreate if not
	  if ( !image_in.isContinuous() )
	  {
		  image_in = image_in.clone();
	  }

	//convert to 8 bit RGB image
	cvtColor(image_in, image_in, CV_8U );


	//create an image for the resultant image (based on the input image_in with no data)
	Mat image_out;
	image_out = image_in.clone();
	image_out.setTo(0xff);

	//create windows to display the images
	namedWindow( "Input Image", CV_WINDOW_AUTOSIZE );
	imshow( "Input Image", image_in );

	namedWindow( "Output Image", CV_WINDOW_AUTOSIZE );
	imshow( "Output Image", image_out );

	//set the debug to FE to enter running mode
	Centurion_Write_Debug(0xFE);

	//wait for user input
	waitKey(1000);


	//set the debug to 1 to select greyscale mode
	Centurion_Write_Debug(0x01);

	//send the image_in in 500 pixel chunks
#define PIXELS_PER_PACKET 1
	int image_size_bytes = image_in.size[0] * image_in.size[1] * image_in.elemSize();
	printf("Image %dx%d, pixel %d bytes. Total Size bytes %d.\n", image_in.size[0], image_in.size[1] , image_in.elemSize(), image_size_bytes);
	int num_packets = image_size_bytes / (PIXELS_PER_PACKET*image_in.elemSize());
	if(image_size_bytes % (PIXELS_PER_PACKET*image_in.elemSize()))
		num_packets ++;
	printf("Packets: %d\n", num_packets);

	Xuint8 *img_data = image_in.ptr(0);
	Xuint8 *img_data_out = image_out.ptr(0);

	Centurion_benchmark_start();
	for(int i=0; i<num_packets; i++)
	{
		printf("Packet: %d:%d\n",i, num_packets);
		printf("Packet: %d %d %d %d\n",img_data[i * PIXELS_PER_PACKET* image_in.elemSize()], img_data[i * PIXELS_PER_PACKET* image_in.elemSize() + 1], img_data[i * PIXELS_PER_PACKET* image_in.elemSize() + 2], img_data[i * PIXELS_PER_PACKET* image_in.elemSize() + 3]);
		//send the data to node 0
		Centurion_Write_Sys_Packet(0, &img_data[i * PIXELS_PER_PACKET* image_in.elemSize()], PIXELS_PER_PACKET * image_in.elemSize(), 0, (i +1) & 0xFF);

		//read the packet
		Centurion_Read_Blocking(&img_data_out[i*PIXELS_PER_PACKET* image_in.elemSize()], PIXELS_PER_PACKET * image_in.elemSize());
		printf("Packet: %d %d %d %d\n",img_data_out[i * PIXELS_PER_PACKET* image_in.elemSize()], img_data_out[i * PIXELS_PER_PACKET * image_in.elemSize()+ 1], img_data_out[i * PIXELS_PER_PACKET * image_in.elemSize()+ 2], img_data_out[i * PIXELS_PER_PACKET * image_in.elemSize()+ 3]);


	}
	printf("Execution time: %fs\n", (Centurion_benchmark_elapsed_us()) / 1000000.0);
	imshow( "Output Image", image_out );

	waitKey(0);

	return 0;

}
