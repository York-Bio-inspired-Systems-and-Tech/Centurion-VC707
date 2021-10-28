#include <stdlib.h>
#include <stdio.h>

//openCV libraries
#include <opencv2/opencv.hpp>
#include <opencv2/imgcodecs.hpp>
#include <highgui.h>

using namespace cv;

int main(int argc, char **argv) {

	printf("Opening the video source\n");

	//openCV provides the Mat type(/class) to store images in
	Mat image_in;

	//read and image from a file
	image_in = imread("/home/mr589/test_img.png", IMREAD_COLOR);

	if (!image_in.data) {
		printf("No image data \n");
		return -1;
	}
	//check if image data is contiguous (no gap between row data). Recreate if not
	if (!image_in.isContinuous()) {
		image_in = image_in.clone();
	}

	//convert to 8 bit RGB image
	cvtColor(image_in, image_in, CV_8U);

	//create an image for the resultant image (based on the input image_in but with no data)
	Mat image_out;
	image_out = image_in.clone();
	//clear the output image holder (set all pixels to white)
	image_out.setTo(0xff);

	//create windows to display the images
	namedWindow("Input Image", WINDOW_NORMAL);
	imshow("Input Image", image_in);

	namedWindow("Output Image", WINDOW_NORMAL);
	imshow("Output Image", image_out);

	int image_size_bytes = image_in.size[0] * image_in.size[1] * image_in.elemSize();

	printf("Image %dx%d, pixel %d bytes. Total Size bytes %d.\n",
			image_in.size[0], image_in.size[1], image_in.elemSize(),
			image_size_bytes);



	//access the
	uchar *img_data = image_in.ptr(0);
	uchar *img_data_out = image_out.ptr(0);

	//copy the first line of the image into the output image
	for(int i=0; i< 32*4; i++){
		printf("image data %d:%x\n", i, img_data[i]);
		img_data_out[i] = img_data[i];
	}

	//display the created image
	imshow("Output Image", image_out);

	//wait for user input
	waitKey(0);

	//go grayscale now
	cvtColor(image_in, image_in, CV_BGR2GRAY);

	//copy the first line of the image into the output image
	for(int i=0; i< 32*4; i++){
		printf("image data grayscale %d:%x\n", i, img_data[i]);
		img_data_out[i] = img_data[i];
	}

	//display the created image
	imshow("Input Image", image_in);
	imshow("Output Image", image_out);

	waitKey(0);

	return 0;

}
