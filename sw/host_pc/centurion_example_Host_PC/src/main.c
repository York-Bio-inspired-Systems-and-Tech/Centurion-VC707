#include <stdlib.h>
#include <stdio.h>

/* required for Centurion functions */
#include "centurion_lib.h"

typedef struct pixel{
	unsigned char red, green, blue;
} PPMPixel;

typedef struct ppm{
	int x, y;
	PPMPixel *data;
} PPMImage;

/* Prototypes */
static PPMImage *readImage(const char *filename);

int main()
{
    /* buffer to store received packets */
	unsigned char buff[10000];

    /* set up the driver for the NoC interface*/
	Centurion_Lib_init();


    /* clear the NoC to a known state */
	Centurion_Reset_NoC();

    /* Allow the nodes to progress beyond " Init_Barrier_Sync()" */
	Centurion_Debug_Node_Broadcast(0xFE);

    Xuint16 header;
	Xuint8 node;
	node = 0;
	buff[0] = 0xAB;
	/* Write a packet to node 0 to start the example message chain! (content is not important)*/
    Centurion_Write_Sys_Packet(node, buff, 1, 0, 0xAA);

    /* Read the input image */
    PPMImage *imagePrint = readImage("test.ppm");

    /* wait for a packet to arrive*/
	Xuint8 packet_len = Centurion_Read_Blocking(&buff, 1000, &header, &node);
	printf("Packet RX, node %d size %d\n", node,packet_len);

    /* print out the packet contents*/
    int i;
	for(i=0; i<packet_len; i++)
	{
		//printf("  D[%2d]: %x\n",i, buff[i]);
	}

    /* close the centurion driver*/
	close(cent_fd);

	return 0;

}

static PPMImage *readImage(const char *filename){
	/* Import the text file of the transformed image */
	char buff[16];
	int lines = 0; // Store how many lines this binary file contains
	int flagImage = 0, i = 0;
	PPMImage *imag;
	FILE * fp = fopen(filename, "r");

	/* Store contents into the array */
	if(!fp){
		printf("Error: file open failed %s. \n", filename);
		exit(1);
	}
	printf("File %s opened successfully. \n\n", filename);

	/* Read image format */
	if(!fgets(buff, sizeof(buff), fp)){
		perror(filename);
		exit(1);
	}

	/* Check the image format */
	if(buff[0] != 'P' || buff[1] != '3'){
		printf("Invalid image format (must be P3) \n");
		exit(1);
	}

	/* Allocate memory from image */
	imag = (PPMImage *)malloc(sizeof(PPMImage));
	if(!imag){
		printf("Unable to allocate memory \n");
		exit(1);
	}

	/* Read image size information */
	if(fscanf(fp, "%d %d", &imag->x, &imag->y) != 2){
		printf("Invalid image size (error loading '%s') \n", filename);
		exit(1);
	}

	while (fgetc(fp) != '\n');
	/* memory allocation for pixel data */
	imag->data = (PPMPixel*)malloc(imag->x * imag->y * sizeof(PPMPixel));
	printf("imag->x: %d, imag->y: %d \n", imag->x, imag->y);

	if(!imag){
		printf("Unable to allocate memory \n");
		exit(1);
	}

	/* Read pixel data from binary file */
	if(fread(imag->data, 3*imag->x, imag->y, fp) != imag->y){
		printf("Error loading image %s \n", filename);
		exit(1);
	}

//	/* Get File length */
//	fseek(ImageFile, 0, SEEK_END);
//	int lengthImage = ftell(ImageFile); // Image binary file length
//	rewind(ImageFile); // Back to the beginning of the file
//
//	/* Get the number of lines of energy */
//	while (i++ < lengthImage){
//		char press = fgetc(ImageFile);
//		/* The return carriage character indicates the end of the file */
//		if(press == '\r' && flagImage == 0){
//			flagImage = 1; // End of the file and set the flag to 1
//		}
//		/* The new line character indicates a line ending */
//		if(press == '\n'){
//			lines++;
//		}
//	}
//	rewind(ImageFile); // Back to the beginning of the file

	/* Print out contents to prove storing successfully */


	/* Close the image to release memory */
	fclose(fp);
	return imag;
}
