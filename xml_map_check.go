package main

import (
	"encoding/xml"
	"fmt"
)

type TestStruct struct {
	Wallets map[uint64]float64 `xml:"wallets"`
}

func main() {
	s := TestStruct{
		Wallets: map[uint64]float64{1: 100.0, 2: 200.0},
	}
	output, err := xml.MarshalIndent(s, "", "  ")
	if err != nil {
		fmt.Println("Error:", err)
	}
	fmt.Println(string(output))
}
