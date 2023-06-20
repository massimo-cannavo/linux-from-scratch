MAIN      := main.go
BIN_DIR   := ../bin
DOWNLOAD  := ${BIN_DIR}/download
MOUNT     := ${BIN_DIR}/mount
PARTITION := ${BIN_DIR}/partition
YAML      := ${BIN_DIR}/yaml

all: $(DOWNLOAD) $(MOUNT) $(PARTITION) $(YAML)

$(DOWNLOAD): download/${MAIN}
	go build -o ${DOWNLOAD} download/${MAIN}

$(MOUNT): mount/${MAIN}
	go build -o ${MOUNT} mount/${MAIN}

$(PARTITION): partition/${MAIN}
	go build -o ${PARTITION} partition/${MAIN}

$(YAML): yaml/${MAIN}
	go build -o ${YAML} yaml/${MAIN}

partition: $(PARTITION)

clean:
	rm ${DOWNLOAD}
	rm ${MOUNT}
	rm ${PARTITION}
	rm ${YAML}
