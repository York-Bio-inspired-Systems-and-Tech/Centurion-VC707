#include <linux/init.h>
#include <linux/module.h>
#include <linux/pci.h>
#include <linux/kernel.h>
#include <linux/syscalls.h>
#include <asm/unistd.h>
#include <linux/ioctl.h>
#include <linux/device.h>

MODULE_LICENSE("GPL");

extern void *sys_call_table[];
static int (*sys_mknod2)(const char*, mode_t, dev_t);
static int cent_open(struct inode* inode, struct file* file);
ssize_t cent_read(struct file* file, const char *buff, size_t count, loff_t *offp);
ssize_t cent_write(struct file* file, const char *buff, size_t count, loff_t *offp);

#ifndef __devinit
#define __devinit
#define __devinitdata
#endif

static int cent_ioctl(struct file* file, unsigned int cmd, unsigned long arg);
static int __devinit probe(struct pci_dev *pdev, const struct pci_device_id *ent);
static int __devinit remove(struct pci_dev *pdev, const struct pci_device_id *ent);

static int dev_file_number =0;

typedef struct {
	int reg;
	int * data;	

}cent_PCI_cmd;


#define CENT_IOC_MAGIC '@' //64d is our major number, don't plug any radeon devices in!
#define CENT_IOC_NULL _IO(CENT_IOC_MAGIC, 0)
#define CENT_IOC_READ_DIP _IOR(CENT_IOC_MAGIC, 1, char)
#define CENT_IOC_WRITE_LEDS _IOW(CENT_IOC_MAGIC, 2, char)

#define CENT_IOC_RESET_NOC _IOW(CENT_IOC_MAGIC, 3, char)
#define CENT_IOC_RESET_RTC _IOW(CENT_IOC_MAGIC, 4, char)

#define CENT_IOC_NODE_DEBUG_READ _IOR(CENT_IOC_MAGIC, 5, char)

#define CENT_IOC_WRITE_REG32 _IOW(CENT_IOC_MAGIC, 6, char)
#define CENT_IOC_READ_REG32 _IOW(CENT_IOC_MAGIC, 7, char)

#define CENT_IOC_SAVE_PCI_STATE _IOW(CENT_IOC_MAGIC, 8, char)
#define CENT_IOC_RESTORE_PCI_STATE _IOW(CENT_IOC_MAGIC, 9, char)
#define CENT_IOC_REPROG_FLASH _IOW(CENT_IOC_MAGIC, 10, char)

#define CENT_IOC_NOC_BUFF_EN _IOW(CENT_IOC_MAGIC, 11, char)
#define CENT_IOC_HS_BUFF_EN _IOW(CENT_IOC_MAGIC, 12, char)
#define CENT_IOC_WR_BUFF_OFFSET_SET _IOW(CENT_IOC_MAGIC, 13, char)
#define CENT_IOC_RD_BUFF_OFFSET_SET _IOW(CENT_IOC_MAGIC, 14, char)

#define CENT_IOC_MAXNR 14



#define CENT_REG_NOC_CNTRL 0x00
#define CENT_REG_NOC_STATUS 0x04
#define CENT_REG_NOC_IF_CNTRL 0x08
#define CENT_REG_NOC_IF_STATUS 0x0C
#define CENT_REG_NOC_IF_TX_LEN 0x10
#define CENT_REG_NOC_IF_RX_LEN 0x14
#define CENT_REG_RTC_VALUE 0x18
#define CENT_REG_NODE_UART_SEL 0x1C
#define CENT_REG_NODE_DEBUG_SEL 0x20
#define CENT_REG_NODE_DEBUG_CMD 0x24
#define CENT_REG_NODE_DEBUG_CMD_VALID 0x28
#define CENT_REG_NODE_LOG_HS_LEN 0x2C
#define CENT_REG_NOC_DEBUG_DATA 0x30

#define CENT_NOC_TX_BASE 0x10000
#define CENT_NOC_RX_BASE 0x10000
#define CENT_NOC_HS_BASE 0x20000

#define CENT_NODE_LOG_DATA 0x20000

#define CENT_PCI_TEST_BRAM 0x40000
#define CENT_PCI_TEST_DIP 0x50000
#define CENT_PCI_TEST_LED 0x50008

#define CENT_PCI_ICAP_BASE_ADDR 0x80000
#define CENT_PCI_ICAP_WR_FIFO_ADDR 0x80100
#define CENT_PCI_ICAP_CNTRL_ADDR 0x8010C


static struct pci_device_id centurion_PCI_id[] = 
{
{	.vendor = 0x10EE,
	.device = 0x7018,
	.subvendor = PCI_ANY_ID, //0x10EE,
	.subdevice = PCI_ANY_ID, //0x10EE,
	.class = 0x00000,//PCI_ANY_ID,//0x058000,
	.class_mask = 0x00000, //PCI_ANY_ID //0x0FF000
	.driver_data =0
},
{}
};

MODULE_DEVICE_TABLE(pci, centurion_PCI_id);

static struct pci_driver centurion_pci_driver = 
{
	.name ="centurion_PCI",
	.id_table = centurion_PCI_id,
	.probe = probe,
	.remove = remove	
};


static struct class *c_dev;
static struct dev_t *dev;

static int __init pci_centurion_init(void)
{
	printk(KERN_ALERT "adding centurion PCI driver table \n");
	int status = pci_register_driver(&centurion_pci_driver);
	if(status < 0)
		printk(KERN_ALERT "ERROR adding centurion PCI driver table \n");

	c_dev = class_create(THIS_MODULE ,"many_core");
	dev = MKDEV(64,0);
	device_create(c_dev, NULL, dev, NULL, "centurion");

	return status;
}

static void __exit pci_centurion_exit(void)
{
	printk(KERN_ALERT "unregistering centurion PCI driver table \n");
	pci_unregister_driver(&centurion_pci_driver);
}


struct file_operations cent_fops = {
 .owner = THIS_MODULE,
 //llseek:  scull_llseek,
 .read = cent_read,
 .write = cent_write,
 .unlocked_ioctl =  cent_ioctl,
.compat_ioctl =  cent_ioctl,
 .open = cent_open
// release: scull_release,
};


void __iomem *buffer;
struct pci_dev hw_dev;

static int __devinit probe(struct pci_dev *pdev, const struct pci_device_id *ent)
{
	printk(KERN_ALERT "centurion PCI enable \n");
	int result = pci_enable_device (pdev);
        if (result < 0)
	{
		printk(KERN_ALERT "centurion PCI enable fail \n");
        	return result;
	}
	printk(KERN_ALERT "centurion PCI enable success \n");

	//check for BAR 0
	printk(KERN_ALERT "centurion PCI BAR0 check\n");
	if (!(pci_resource_flags(pdev, 0) & IORESOURCE_MEM)) 
	{
		printk(KERN_ALERT "Incorrect BAR configuration.\n");
		return -ENODEV;
	}

	//request BAR0 memory space
	long iobase = pci_resource_start (pdev, 0);
	long iosize = pci_resource_len (pdev, 0);
	long ioflags = pci_resource_flags (pdev, 0);

	printk(KERN_ALERT "BAR0 @ %X, %x, %d bytes\n", iobase, ioflags, iosize );
	
	pci_request_region(pdev, 0, "centurion_BAR0");
	
	
	//buffer = pci_iomap(pdev, 0, 0);
	buffer = ioremap_nocache(pci_resource_start(pdev,0) ,pci_resource_len(pdev,0));

	printk(KERN_ALERT "IOmap addr %x \n", buffer);
	char temp;
	pci_read_config_byte(pdev,0x04, &temp);
	printk(KERN_ALERT "int reg %x \n", temp);
	temp |= 0x04;
	pci_write_config_byte(pdev,0x04, temp);
	//pci_read_config_byte(pdev,0x04, &temp);
	//printk(KERN_ALERT "int reg %x \n", temp);

	volatile int dip_switch = ioread32(buffer + 0x50000 );
	printk(KERN_ALERT "Dipswitch @ %X, %x\n", buffer, dip_switch );
	iowrite32(0xAB, buffer + 0x50000 + 8);
	
	dip_switch = ioread32(buffer + 0x40000);
	printk(KERN_ALERT "BRAM @ %X, %x\n", buffer, dip_switch );
	iowrite32(0xCB, buffer + 0x40000);
	dip_switch = ioread32(buffer + 0x40000);
	printk(KERN_ALERT "BRAM @ %X, %x\n", buffer, dip_switch );


	//mmiowb();
	//*(int*)iobase = 0xAAAAAAAA;

	//reserve a device number (currently hardcoded)
	 dev_file_number = register_chrdev(64, "centurion", &cent_fops);
	 if (result < 0) 
	{
	  printk(KERN_WARNING "can't get major %d\n",dev_file_number);
	  return result;
	 }
	
	hw_dev = *pdev;

	return 0;

}


static int cent_open(struct inode* inode, struct file* file)
{
	printk(KERN_ALERT "centurion Open\n");

	//kernel will hang without a successful return code!
	return 0;
}

void *mem_write_offset = CENT_NOC_TX_BASE;
void *mem_read_offset = CENT_NOC_RX_BASE;

ssize_t cent_read(struct file* file, const char *buff, size_t count, loff_t *offp)
{
	//printk(KERN_ALERT "centurion read\n");
	unsigned int k_buff[count];
	int i;
	for(i=0; i<count; i++)
	{	if(i < 5)
			printk(KERN_ALERT "centurion read %x @ %X:%X\n", ioread32(buffer + (unsigned int)mem_read_offset + (i*4)), buffer, buffer + (unsigned int)mem_read_offset + (i*4));
		k_buff[i] = ioread32(buffer + (unsigned int)mem_read_offset + (i*4));
	}
	copy_to_user(buff, (const void*)k_buff, count*4);
	return count;
}

ssize_t cent_write(struct file* file, const char *buff, size_t count, loff_t *offp)
{
	//printk(KERN_ALERT "centurion write: %d words\n", count);
	unsigned short k_buff[count];
	int i;
	copy_from_user(k_buff, (const void*)buff, count*2);
	for(i=0; i<count; i++)
	{
		if(i < 5)
			printk(KERN_ALERT "centurion write %x @ %X:%X\n", k_buff[i], buffer, buffer + (unsigned int)mem_write_offset + (i*4));
		iowrite32(k_buff[i], buffer + (unsigned int)mem_write_offset + (i*4));
	}

	return count;
}


static int cent_ioctl(struct file* file, unsigned int cmd, unsigned long arg)
{
	//printk(KERN_ALERT "Centurion IOCTL: %d\n", cmd); 
	if(_IOC_TYPE(cmd) != CENT_IOC_MAGIC) return -ENOTTY;
	if(_IOC_NR(cmd) > CENT_IOC_MAXNR) return -ENOTTY;	

	int return_value = 0;
	char leds;
	int i;
	int write_data;
	cent_PCI_cmd *cent_cmd = (cent_PCI_cmd*)arg;


	switch(cmd)
	{
			

		case CENT_IOC_READ_DIP:
			return_value = put_user(ioread32(buffer + CENT_PCI_TEST_DIP), (int *)arg);
			break;			

		case CENT_IOC_WRITE_LEDS:
			return_value = get_user(leds, (int *)arg);
			iowrite32(leds, buffer + 8 + 0x10000);
			break;

		case CENT_IOC_WRITE_REG32:
			get_user(write_data, (int*)(cent_cmd->data));
			printk(KERN_ALERT "Writing %X, to %x\n", write_data, (cent_cmd->reg));
			iowrite32(write_data, buffer + (cent_cmd->reg));
			break;
	
		case CENT_IOC_READ_REG32:
			//printk(KERN_ALERT "Reading %X, from %x\n", ioread32(buffer + (cent_cmd->reg)), (cent_cmd->reg));
			put_user(ioread32(buffer + (cent_cmd->reg)), cent_cmd->data);
			break;

		case CENT_IOC_RESET_NOC:
			iowrite32(0x05, buffer + CENT_REG_NOC_CNTRL);
			for(i=0; i<100; i++);
			iowrite32(0x00, buffer + CENT_REG_NOC_CNTRL);
			break;

		case CENT_IOC_RESET_RTC:
			iowrite32(0x02, buffer + CENT_REG_NOC_CNTRL);
			for(i=0; i<100; i++);
			iowrite32(0x00, buffer + CENT_REG_NOC_CNTRL);
			break;

		case CENT_IOC_NODE_DEBUG_READ:
			iowrite32(0x00, buffer + CENT_REG_NODE_DEBUG_SEL);
			iowrite32(0x00, buffer + CENT_REG_NODE_UART_SEL);
			return_value = put_user(ioread32(buffer + 0x2c), (int *)arg);
			printk(KERN_ALERT "Dipswitch IOCTL @ %X, %x\n", buffer, ioread32(buffer + CENT_REG_NOC_CNTRL) );
			printk(KERN_ALERT "RTC VALUE @ %X, %x\n", buffer, ioread32(buffer + 0x30) );
			break;

		case CENT_IOC_SAVE_PCI_STATE:
			return_value = pci_save_state(&hw_dev);
			printk(KERN_ALERT "PCI state saved %d\n", return_value);
			break;

		case CENT_IOC_RESTORE_PCI_STATE:
			pci_restore_state(&hw_dev);
			printk(KERN_ALERT "PCI state restored\n");
			break;

		case CENT_IOC_REPROG_FLASH:
			//write the reprogram command to the ICAP
			//set warm boot addr to 0 (as given in XTP226)
			printk(KERN_ALERT "Reloading FPGA from flash\n");
			printk(KERN_ALERT "ICAP status %x\n", ioread32(buffer+ 0x80110));
			printk(KERN_ALERT "ICAP status %x\n", ioread32(buffer+ 0x80114));
			iowrite32(0xFFFFFFFF, buffer + CENT_PCI_ICAP_WR_FIFO_ADDR);
			iowrite32(0xAA995566, buffer + CENT_PCI_ICAP_WR_FIFO_ADDR);
			iowrite32(0x20000000, buffer + CENT_PCI_ICAP_WR_FIFO_ADDR);
			iowrite32(0x30020001, buffer + CENT_PCI_ICAP_WR_FIFO_ADDR);
			iowrite32(0x00000000, buffer + CENT_PCI_ICAP_WR_FIFO_ADDR);
			iowrite32(0x00000001, buffer + CENT_PCI_ICAP_CNTRL_ADDR);
			iowrite32(0x00000000, buffer + CENT_PCI_ICAP_CNTRL_ADDR);
			//Issue flash program command (as given in XTP226)
			iowrite32(0x30008001, buffer + CENT_PCI_ICAP_WR_FIFO_ADDR);
			iowrite32(0x0000000F, buffer + CENT_PCI_ICAP_WR_FIFO_ADDR);
			iowrite32(0x20000000, buffer + CENT_PCI_ICAP_WR_FIFO_ADDR);
			iowrite32(0x00000001, buffer + CENT_PCI_ICAP_CNTRL_ADDR);
			
			iowrite32(0x00000000, buffer + CENT_PCI_ICAP_CNTRL_ADDR);
			printk(KERN_ALERT "Flash done\n");
			printk(KERN_ALERT "ICAP status %x\n", ioread32(buffer+ 0x80110));
			printk(KERN_ALERT "ICAP status %x\n", ioread32(buffer+ 0x80114));
			break;

		case CENT_IOC_NOC_BUFF_EN:
			mem_write_offset = CENT_NOC_TX_BASE;
			mem_read_offset = CENT_NOC_RX_BASE;
			break;

		case CENT_IOC_HS_BUFF_EN:
			mem_write_offset = CENT_NOC_HS_BASE;
			mem_read_offset = CENT_NOC_HS_BASE;
			break;

		case CENT_IOC_WR_BUFF_OFFSET_SET:
			mem_write_offset = (void*)arg;
			break;

		case CENT_IOC_RD_BUFF_OFFSET_SET:
			mem_read_offset = (void*)arg;
			break;

		default:
			printk(KERN_ALERT "Centurion BAD IOCTL: %d\n", cmd);
			break; 	

	}
	return return_value;
}


static int __devinit remove(struct pci_dev *pdev, const struct pci_device_id *ent)
{
	printk(KERN_ALERT "centurion PCI destroy \n");
	unregister_chrdev(64, "centurion");

	device_destroy(c_dev, dev);
	class_destroy(c_dev);

	pci_iounmap(pdev, buffer);
	pci_release_regions(pdev);
	pci_disable_device(pdev);
	printk(KERN_ALERT "centurion PCI destroy done\n");
}

module_init(pci_centurion_init);
module_exit(pci_centurion_exit);


