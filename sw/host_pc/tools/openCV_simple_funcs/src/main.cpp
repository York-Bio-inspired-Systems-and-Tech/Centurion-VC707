#include <stdlib.h>
#include <stdio.h>

//openCV libraries
#include <opencv2/opencv.hpp>
#include <opencv2/imgcodecs.hpp>
#include <highgui.h>

using namespace cv;

int main(int argc, char **argv) {

	printf("Opening the image source\n");

	//openCV provides the Mat type(/class) to store images in
	Mat image_in;

	//read and image from a file
	image_in = imread("/home/mr589/test_img.png", IMREAD_COLOR);

	if (!image_in.data) {
		printf("No image data \n");
		return -1;
	}

	//create a window to display the images
	namedWindow("Input Image", WINDOW_NORMAL);
	imshow("Input Image", image_in);


	waitKey(0);

	return 0;

}
