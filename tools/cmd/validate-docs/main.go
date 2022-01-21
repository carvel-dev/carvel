// Copyright 2021 VMware, Inc.
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"regexp"
	"strings"

	"gopkg.in/yaml.v2"
)

type Tool struct {
	VersionLatest string `yaml:"version_latest"`
}

type Params struct {
	Tools map[string]Tool
}

func (e *Params) UnmarshalYAML(unmarshal func(interface{}) error) error {
	var params struct {
	}
	if err := unmarshal(&params); err != nil {
		return err
	}

	var tools map[string]Tool
	if err := unmarshal(&tools); err != nil {
		if _, ok := err.(*yaml.TypeError); !ok {
			return err
		}
	}
	e.Tools = tools
	return nil
}

type ConfigFile struct {
	Params Params `yaml:"params"`
}

func main() {
	var diffFile, hugoConfigurationFile string
	flag.StringVar(&diffFile, "diff", "", "Location of the file generated using the giff diff command")
	flag.StringVar(&hugoConfigurationFile, "cfg", "", "Path to the file with hugo configuration")

	flag.Parse()

	if diffFile == "" {
		log.Fatalf("Diff file not provided, use `-diff` flag")
	}
	if hugoConfigurationFile == "" {
		log.Fatalf("Hugo configuration file not provided, use `-cfg` flag")
	}
	foldersFound, err := readDifferenceFile(diffFile)

	conf := ConfigFile{}
	configFile, err := ioutil.ReadFile(hugoConfigurationFile)
	if err != nil {
		log.Fatalf("Unable to open configuration file: %s", err)
	}

	err = yaml.Unmarshal(configFile, &conf)
	if err != nil {
		log.Fatalf("Unable to unmarshal configuration file: %s", err)
	}

	errOutput := checkChangesMade(foldersFound, conf)

	if errOutput != "" {
		log.Fatalf(fmt.Sprintf("Changes found in documentation:\n%s\nDocumentation changes for older versions are fozen, make sure you really want to change them.", errOutput))
	}

	log.Println("No changes were made on frozen documentation")
}

func checkChangesMade(foldersFound map[string]map[string]bool, conf ConfigFile) string {
	errOutput := ""
	for tool, versions := range foldersFound {
		changedLatestVersion := false
		var changedVersions []string
		for version, _ := range versions {
			changedVersions = append(changedVersions, version)
			if version == conf.Params.Tools[tool].VersionLatest {
				changedLatestVersion = true
			}
		}

		if changedLatestVersion {
			continue
		}
		if len(changedVersions) > 0 {
			errOutput = fmt.Sprintf("%sChanged '%s' documentation on versions: %v\n", errOutput, tool, changedVersions)
		}
	}
	return errOutput
}

func readDifferenceFile(diffFile string) (map[string]map[string]bool, error) {
	file, err := ioutil.ReadFile(diffFile)
	if err != nil {
		log.Fatalf("Unable to open file with diff: %s", err)
	}

	foldersFound := map[string]map[string]bool{}

	filesChanged := strings.Split(string(file), "\n")
	for _, filename := range filesChanged {
		re := regexp.MustCompile("site/content/([^/]+)/docs/(v[^/]*)+/")
		isVersionedDoc := re.MatchString(filename)
		if !isVersionedDoc {
			continue
		}
		matches := re.FindAllStringSubmatch(filename, -1)
		if len(matches) != 1 {
			continue
		}
		if len(matches[0]) != 3 {
			log.Fatalf("failed %v", matches)
		}

		if _, ok := foldersFound[matches[0][1]]; !ok {
			foldersFound[matches[0][1]] = map[string]bool{}
		}
		foldersFound[matches[0][1]][matches[0][2]] = true
	}
	return foldersFound, err
}
