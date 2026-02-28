#include "xaxidma.h"
#include "xparameters.h"

#define NUM_SAMPLES         154
#define NUM_FEATURES        8

#define TX_BUFFER_SIZE      (NUM_SAMPLES * NUM_FEATURES * 2) // 16-bit = 2 bytes (128 bits for each input , (128*154)/8 bytes
#define RX_BUFFER_SIZE      (NUM_SAMPLES * 4)                // 32-bit = 4 bytes (each prediction is 32 bit long)  (32*154)/8 bytes

#define TX_MEM_ADDR         0x10000000
#define RX_MEM_ADDR         0x11000000

#define XPAR_AXI_DMA_0_BASEADDR 0x40400000

int main(){

	XAxiDma_Config* myDmaConfig;
	XAxiDma myDma;

	myDmaConfig=XAxiDma_LookupConfig(XPAR_AXI_DMA_0_DEVICE_ID);

	XAxiDma_CfgInitialize(&myDma, myDmaConfig);
	xil_printf("Arming RX DMA at address 0x%X...\r\n", RX_MEM_ADDR); //(S2MM first)
	XAxiDma_SimpleTransfer(&myDma, RX_MEM_ADDR, RX_BUFFER_SIZE, XAXIDMA_DEVICE_TO_DMA);

	xil_printf("Firing TX DMA from address 0x%X...\r\n", TX_MEM_ADDR); //(MM2S)
	XAxiDma_SimpleTransfer(&myDma, TX_MEM_ADDR, TX_BUFFER_SIZE, XAXIDMA_DMA_TO_DEVICE);

	//Poll till Completion
	 while (XAxiDma_Busy(&myDma, XAXIDMA_DMA_TO_DEVICE)) {}
	 while (XAxiDma_Busy(&myDma, XAXIDMA_DEVICE_TO_DMA)) {}

	 xil_printf("Hardware Inference Complete Check DRAM for results.\r\n");
	 return 0;
}
