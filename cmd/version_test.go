package cmd

import (
	"bytes"
	"io/ioutil"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestCmdVersionNoArgs(t *testing.T) {
	cmd := NewVersionCmd()
	b := bytes.NewBufferString("")
	cmd.SetOut(b)
	cmd.SetArgs([]string{"version"})
	err := cmd.Execute()
	assert.Nil(t, err)
	out, err := ioutil.ReadAll(b)
	assert.Nil(t, err)
	assert.Regexp(t, `^waver version: \w+ from commit \w+ built on \w+$`, string(out))
}

func TestCmdVersionCommitArg(t *testing.T) {
	cmd := NewVersionCmd()
	b := bytes.NewBufferString("")
	cmd.SetOut(b)
	cmd.SetArgs([]string{"version", "--commit"})
	err := cmd.Execute()
	assert.Nil(t, err)
	out, err := ioutil.ReadAll(b)
	assert.Nil(t, err)
	assert.Regexp(t, `^([-a-f0-9]{40}|unknown)$`, string(out))
}
