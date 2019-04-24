package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"math/rand"
	"os"
	"time"

	"github.com/k14s/k14s.io/pkg/cmd"
)

func main() {
	rand.Seed(time.Now().UTC().UnixNano())
	log.SetOutput(ioutil.Discard)

	command := cmd.NewDefaultK14sIoCmd()

	err := command.Execute()
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Succeeded\n")
}
