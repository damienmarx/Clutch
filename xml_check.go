package main

import (
	"encoding/xml"
	"fmt"
	"errors"
)

type jerr struct {
	error
}

func (err jerr) MarshalXML(e *xml.Encoder, start xml.StartElement) error {
	return e.EncodeElement(err.Error(), start)
}

type ajaxerr struct {
	XMLName xml.Name `json:"-" yaml:"-" xml:"error"`
	What    jerr     `json:"what" yaml:"what" xml:"what"`
	Code    int      `json:"code,omitempty" yaml:"code,omitempty" xml:"code,omitempty"`
	UID     uint64   `json:"uid,omitempty" yaml:"uid,omitempty" xml:"uid,omitempty,attr"`
}

func main() {
	err := ajaxerr{
		What: jerr{errors.New("test error")},
		Code: 400,
		UID:  123,
	}
	output, _ := xml.MarshalIndent(err, "", "  ")
	fmt.Println(string(output))
}
