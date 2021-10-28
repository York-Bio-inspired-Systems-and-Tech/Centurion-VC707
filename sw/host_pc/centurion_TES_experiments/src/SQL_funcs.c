
#define HAVE_REMOTE

#include <fcntl.h>   /* File control definitions */
#include "sqlite3.h"
#include <sys/ipc.h>
#include <sys/msg.h>
#include <mqueue.h>

#define NOC_NUM_NODES 128

#define RESULTS_DB_PATH "/media/sf_mr589_local/thesis_results.db"

int SQLite_connect();
void SQLite_save_run_data(unsigned char *data, int r_id, int run);

typedef struct
{
	uint32_t command;
	uint32_t *indices;
	uint32_t *data;
	uint32_t run;
	uint32_t sweep;
}SQLite_msg;

int sqlite_MSG_queue_id;
volatile uint32_t current_RID;


uint8_t current_db[128] = {0};
uint8_t current_desc[256] = {0};
uint8_t current_param[128] = {0};

uint32_t sweep_total = 0;
uint32_t current_sweep = 0;


/* prototype of the packet handler */
void packet_handler(u_char *param, const struct pcap_pkthdr *header, const u_char *pkt_data);
pcap_t *adhandle;



pthread_t eth_RX_thread;
void Eth_RX();

pthread_t sqlite_thread;
void sqlite_RX_thread();

// gcc -DWPCAP -DHAVE_REMOTE -I/usr/include/pcap/ gig_eth_pcap.c -lwpcap && ./a.exe

void sigint_handler(int signum)
{
	printf("ctrl-c catch\n");
	exit(1);
}

main()
{

	struct mq_attr attr, *attrp;
	 attr.mq_maxmsg = 256;
	 attr.mq_msgsize = 1024;
	 attrp = &attr;
	 mode_t mode  = S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH;

	 attr.mq_msgsize = sizeof(SQLite_msg);
	sqlite_MSG_queue_id = mq_open("/sqlite_msg", O_RDWR | O_CREAT,  mode, attrp);
	if(sqlite_MSG_queue_id == -1)
	{
		perror("Error opening sqlite_MSG_queue_id msg queue\n");
	}
	printf("sqlite message queue: %d\n", sqlite_MSG_queue_id);








	signal(SIGINT, sigint_handler);

	int inum;


    pcap_if_t *alldevs;
    pcap_if_t *d;
	int i=0;
	int found = 0;
    char errbuf[PCAP_ERRBUF_SIZE];

    /* Retrieve the device list from the local machine */
    if (pcap_findalldevs_ex(PCAP_SRC_IF_STRING, NULL /* auth is not needed */, &alldevs, errbuf) == -1)
    {
        fprintf(stderr,"Error in pcap_findalldevs_ex: %s\n", errbuf);
        exit(1);
    }

    /* Print the list */
    for(d= alldevs; d != NULL; d= d->next)
    {
		printf("%d. %s", ++i, d->name);
        if (d->description)
            printf(" (%s)\n", d->description);
        else
            printf(" (No description available)\n");

		if(strcmp(d->name, "rpcap://\\Device\\NPF_{6AC76C92-3E24-4A2A-AFE8-C0944A0B4FA9}") == 0)
		{
			printf("gig eth found\n");
			found = '1';
			break;
		}
    }



	if(found == 0)
	{
		printf("Didn't find the gig eth\n");
		return;
	}

	//pcap_set_buffer_size(adhandle, 65536);



    // /* Open the device */
    // if ( (adhandle= pcap_open(d->name,          // name of the device
                              // 10240,            // portion of the packet to capture
                                                // // 65536 guarantees that the whole packet will be captured on all the link layers
                              // PCAP_OPENFLAG_PROMISCUOUS,    // promiscuous mode
                              // 0,             // read timeout
                              // NULL,             // authentication on the remote machine
                              // errbuf            // error buffer
                              // ) ) == NULL)
    // {
        // fprintf(stderr,"\nUnable to open the adapter. %s is not supported by WinPcap\n", d->name);
        // /* Free the device list */
        // pcap_freealldevs(alldevs);
        // return -1;
    // }

	adhandle =  pcap_create(d->name, errbuf);
	printf("snaplen : %d\n", pcap_set_snaplen(adhandle, 10240));
	printf("promiscuous : %d\n", pcap_set_promisc(adhandle, 1));
	printf("timeout : %d\n", pcap_set_timeout(adhandle, 512));

	printf("activate: %d\n", pcap_activate(adhandle));


    printf("\nlistening on %s...\n", d->description);

    /* At this point, we don't need any more the device list. Free it */
    pcap_freealldevs(alldevs);


	 pthread_create(&eth_RX_thread, NULL, Eth_RX, NULL);
	 //create sqlite results thread
    pthread_create(&sqlite_thread, NULL, sqlite_RX_thread, NULL);



	char c;
	fcntl (0, F_SETFL, O_NONBLOCK);
	while(read (0, &c, 1) != 0)
	{
		/*char buffer[1024];
		int n = read(fd, buffer, sizeof(buffer));
		if (n < 0)
			fputs("read failed!\n", stderr);
		else
			printf("%s", buffer);*/
    }
    return 0;
}


void Eth_RX()
{
	 /* start the capture */
    pcap_loop(adhandle, 0, packet_handler, NULL);

}
	uint8_t* current_data_buff;
	uint32_t current_data_index;
    SQLite_msg msg;
/* Callback function invoked by libpcap for every incoming packet */
void packet_handler(u_char *param, const struct pcap_pkthdr *header, const u_char *pkt_data)
{

    struct tm *ltime;
    char timestr[16];
    time_t local_tv_sec;

    /* convert the timestamp to readable format */
    local_tv_sec = header->ts.tv_sec;
    ltime=localtime(&local_tv_sec);
    strftime( timestr, sizeof timestr, "%H:%M:%S", ltime);

	struct pcap_stat stats;
	pcap_stats(adhandle, &stats);
	printf("dropped %d\n", stats.ps_drop);

    printf("%s,%.6d len:%d\n", timestr, header->ts.tv_usec, header->len);

	//throw away all packets that don't have our mac address as the destn
	/*unsigned int match =0;
	int i;
	for(i=0; i<6;i++)
		match += abs((unsigned char)if_mac.ifr_hwaddr.sa_data[i] - eth_buff[i]);
	if(match != 0)
		continue;*/

//		printf("eth rx %d\n", length);


	int i;
/*	for(i=0; i<header->len; i++)
	{
		printf("%5d: %2x : %c\n", i, pkt_data[i], pkt_data[i]);
	}*/

	unsigned short payload_len = pkt_data[12] << 8;
	payload_len |= pkt_data[13] & 0xFF;
	//read the type (word @ 14)
	uint32_t p_type = pkt_data[14] << 24;
	p_type |= pkt_data[15] << 16;
	p_type |= pkt_data[16] << 8;
	p_type |= pkt_data[17] & 0xFF;

	//read the app data (word @ 18)
	uint32_t app_data = pkt_data[18] << 24;
	app_data |= pkt_data[19] << 16;
	app_data |= pkt_data[20] << 8;
	app_data |= pkt_data[21] & 0xFF;

	//read the packet sequence number (word @ 22)
	uint32_t seq_num = pkt_data[22] << 24;
	seq_num |= pkt_data[23] << 16;
	seq_num |= pkt_data[24] << 8;
	seq_num |= pkt_data[25] & 0xFF;

	//read the total number of packets in this sequence (word @ 26)
	uint32_t packet_total = pkt_data[26] << 24;
	packet_total |= pkt_data[27] << 16;
	packet_total |= pkt_data[28] << 8;
	packet_total |= pkt_data[29] & 0xFF;

	//if the app id is 2 then a new set of results have come in
	printf("RX eth! %d, type: %d, APP_data: %X, Seq: %d of %d\n", header->len,p_type, app_data, seq_num, packet_total);
	switch(p_type)
	{
		case 2:
		{
			//malloc space for the indices
			uint32_t* buff = malloc(NOC_NUM_NODES * 4 + 520);
			msg.indices = buff;
			//copy over the data
			int i;
			for(i=0; i< (NOC_NUM_NODES * 4) + 520; i++)
			{
				((uint8_t*)buff)[i] = pkt_data[30 + i];
			}
			//count the log size
			unsigned int num_entries = 0;
			for(i=0; i<NOC_NUM_NODES; i++)
			{
				//swap endianess (data is read on V5, which is BE...)
				buff[i] = __bswap_32(buff[i]);
				num_entries +=  buff[i];
					printf("Node %d: entries: %d\n", i, buff[i]);
			}
			printf("Number of log entries: %d\n", num_entries);

			for(i=NOC_NUM_NODES; i<NOC_NUM_NODES + 64 + 32 +32 + 2; i++)
			{
				buff[i] = __bswap_32(buff[i]);
			}

			uint8_t* db_name = &buff[128];
			uint8_t* db_desc = &buff[128 + 32];
			uint8_t* db_param = &buff[128 + 64 + 32];
			uint32_t db_sweep_total = *((uint32_t*)&buff[128 + 64 + 32 + 32]);
			uint32_t db_sweep_curr = *((uint32_t*)&buff[128 + 64 + 32 +32 + 1]);

			//read the metadata
			printf("DB name: %s\n", db_name);
			printf("Desc: %s\n", db_desc);
			printf("Param: %s\n", db_param);
			printf("Sweep Total: %d\n", db_sweep_total);
			printf("This Sweep: %d\n",  db_sweep_curr);
			printf("Sweep Total: %x\n", db_sweep_total);
			printf("This Sweep: %x\n",  db_sweep_curr);


			stpcpy(current_db, db_name);
			stpcpy(current_desc, db_desc);
			stpcpy(current_param, db_param);

			uint32_t sweep_total = 0;
			uint32_t current_sweep = 0;

			//malloc space for the data

			current_data_buff = malloc(num_entries * 8);
			msg.data = current_data_buff;
			msg.run = app_data;
			msg.sweep = db_sweep_curr;
			current_data_index =0;
			break;
		}
		case 3:
		{
			//length is packet length - header
			uint32_t data_len = payload_len;
			printf("type 3, len: %d, i: %d\n", data_len, current_data_index);
			//copy over the data
			for(i=0; i<data_len; i++)
			{
				current_data_buff[current_data_index] = pkt_data[30 + i];
				current_data_index++;
			}
			printf("copied\n");
			//check if this was the last packet (node == 127 and sequence == num sub packets)
			if(app_data == NOC_NUM_NODES-1 && seq_num == packet_total)
			{
				msg.command = 0xAD;
				int msg_len = mq_send(sqlite_MSG_queue_id, &msg, sizeof(msg), NULL);
				if(msg_len < 0)
				{
					perror("ERROR adding message to queue... ");
				}
			}

			break;
		}

	}


}








void SQLite_transaction_start(sqlite3* db)
{
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
}
void SQLite_transaction_end(sqlite3* db)
{
	sqlite3_exec(db, "END TRANSACTION", NULL, NULL, NULL);
}


double get_time()
{
    struct timeval t;
    gettimeofday(&t, NULL);
    return t.tv_sec + t.tv_usec*1e-6;
}



int SQLite_Prepared_Add_Event(sqlite3* db, char* query, sqlite3_stmt* stmt, int result_id, int run, uint8_t node, uint8_t event, uint32_t time, uint8_t p0, uint8_t p1, uint8_t p2)
{
	sqlite3_bind_int(stmt, 1, result_id);
	sqlite3_bind_int(stmt, 2, run);
	sqlite3_bind_int(stmt, 3, node);
	sqlite3_bind_int(stmt, 4, event);
	sqlite3_bind_int(stmt, 5, time);
	sqlite3_bind_int(stmt, 6, p0);
	sqlite3_bind_int(stmt, 7, p1);
	sqlite3_bind_int(stmt, 8, p2);
	int res;
	while((res = sqlite3_step(stmt)) != SQLITE_DONE)
	{
		switch(res)
		{
        	case SQLITE_ERROR:
				fprintf(stderr, "step error: %s\n", sqlite3_errmsg(db));
				sqlite3_close_v2(db);
				exit(1);
				break;
        	case SQLITE_BUSY:
				printf("SQLite busy\n");
				break;
        	case SQLITE_MISUSE:
				printf("SQL MISUSE\n");
				break;
        	default:
        		printf("err: %x\n", res);
        		printf("SQL query %s\n", query);
        		printf("MSG %s.\n", sqlite3_errmsg(db));
        		//while(1);
        		goto end;
        		break;

		}


	}
end:
	//printf("SQL add ok\n");
	 sqlite3_reset(stmt);

	//fetch the ID from res
	return 1;
}


sqlite3 *results_db;
int SQLite_connect()
{
	if(sqlite3_open(current_db, &results_db))
	{
		fprintf(stderr, "Can't open database: %s\n", sqlite3_errmsg(results_db));
		sqlite3_close(results_db);
		return(0);
	}
    printf("SQLite connect successful\n");


	return 1;

}



void sqlite_RX_thread()
{
	printf("sql thread started\n");
	sqlite3 * thread_db = 0;
	char msg_buff[1024];
	char db_name[1024];
	SQLite_msg* msg = (SQLite_msg*)msg_buff;
	unsigned char action;
	unsigned char node;
	unsigned int total_log_entries;
	unsigned int log_entries;
	unsigned int time;
	unsigned char p0,p1,p2;


	while(1)
	{
		int msg_len = mq_receive(sqlite_MSG_queue_id, msg_buff, 1024, NULL);
	//	printf("SQLite msg rx %d\n", msg_len);
		if(msg_len < 0)
		{
			perror("msg RX fail");
			while(1);
		}

		sprintf(db_name, "./results/%s.db", current_db);

		sqlite3_close(thread_db);

		if(sqlite3_open(db_name, &thread_db))
		{
			fprintf(stderr, "Can't open database: %s\n", sqlite3_errmsg(thread_db));
			sqlite3_close(thread_db);
			while(1);
		}
		printf("SQLite connect successful\n");
		//sqlite3_exec(thread_db, "create table if not exists data (result_id INTEGER, run INTEGER, node INTEGER, event INTEGER, time INTEGER, p0 INTEGER, p1 INTEGER, p2 INTEGER, PRIMARY KEY (result_id ASC, run ASC, node ASC, event, time ASC)) WITHOUT ROWID", NULL, NULL, NULL);
		sqlite3_exec(thread_db, "create table if not exists data (result_id INTEGER, run INTEGER, node INTEGER, event INTEGER, time INTEGER, p0 INTEGER, p1 INTEGER, p2 INTEGER)", NULL, NULL, NULL);

		sqlite3_exec(thread_db, "create index if not exists sweep_run_event on data (result_id ASC, run ASC, event ASC, node ASC)", NULL, NULL, NULL);


		sqlite3_exec(thread_db, "PRAGMA journal_mode = MEMORY", NULL, NULL, NULL);
		sqlite3_exec(thread_db, "PRAGMA synchronous = OFF", NULL, NULL, NULL);

		char insert_string[] = "INSERT INTO data VALUES (?1,?2,?3,?4,?5,?6,?7,?8)";
		sqlite3_stmt *insert_stmt;
		int res = sqlite3_prepare_v2(thread_db, insert_string, strlen(insert_string), &insert_stmt, NULL);














		int i,j;
		uint8_t* data = (uint8_t*)msg->data;
		uint32_t d_i = 0;
		total_log_entries = 0;


		SQLite_transaction_start(thread_db);
		double  t1 = get_time();

		for(i=0; i<NOC_NUM_NODES; i++)
		{
			log_entries = msg->indices[i];
			total_log_entries += log_entries;
//			printf("Node %d, num %d @ %x\n", i, log_entries, &(data[d_i]));

			for(j=0; j< log_entries; j++)
			{
				//order is backwards due to BE endianess of V5...
				 action = data[d_i++];
				 p2 = data[d_i++];
				 p1 = data[d_i++];
				 p0 = data[d_i++];
				 time = data[d_i++] << 24;
				 time |= data[d_i++] << 16;
				 time |= data[d_i++] << 8;
				 time |= data[d_i++] & 0xFF;
//				 printf("N:%d a:%d t:%d p0:%d p1:%d p2:%d \n", i, action,time, p0, p1, p2);
				 SQLite_Prepared_Add_Event(thread_db, insert_string, insert_stmt, msg->sweep, msg->run, i, action, time, p0, p1, p2);

			}
		}
		sqlite3_exec(thread_db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		sqlite3_finalize(insert_stmt);
		double  t2 = get_time();
		SQLite_transaction_end(thread_db);

		printf("run %d, experiment %d. %d result entries in %fs, %fsecs/insert\n", msg->run+1, msg->sweep, total_log_entries, t2-t1, (t2-t1) / total_log_entries);




		//printf("free start %x\n",msg->data);
		free(msg->data);
	//	printf("free 1 done %x\n",msg->indices);
		free(msg->indices);
	//	printf("free 2 done\n");
	}
}



