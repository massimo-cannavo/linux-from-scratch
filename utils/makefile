BIN_DIR   := ../bin
DOWNLOAD  := ${BIN_DIR}/download
MOUNT     := ${BIN_DIR}/mount
PARTITION := ${BIN_DIR}/partition

all: $(DOWNLOAD) $(MOUNT) $(PARTITION)

$(DOWNLOAD): download/main.go
	go build -o ${DOWNLOAD} download/main.go

$(MOUNT): mount/main.go
	go build -o ${MOUNT} mount/main.go

$(PARTITION): partition/main.go
	go build -o ${PARTITION} partition/main.go

partition: $(PARTITION)

clean:
	rm ${DOWNLOAD}
	rm ${MOUNT}
	rm ${PARTITION}
