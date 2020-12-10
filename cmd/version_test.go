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

// TestCmdPrintVersion will validate the output string
// when build with various flags. This command must not be
// run in parallel as there are global options which are
// configured during normal builds using ldflags.
func TestCmdPrintVersion(t *testing.T) {
	tests := []struct {
		version       string
		commit        string
		date          string
		expect        string
		verboseOutput bool
	}{
		{
			"a",
			"b",
			"c",
			"waver version: a from commit b built on c",
			true,
		}, {
			"v0.12.4",
			"5b1a61f9b58e3778986c99b1282840ce64329614",
			"Thu May 21 16:48:18 PDT 2020",
			"waver version: v0.12.4 from commit 5b1a61f9b58e3778986c99b1282840ce64329614 built on Thu May 21 16:48:18 PDT 2020",
			true,
		}, {
			"v0.12.4-rc5",
			"5b1a61f9b58",
			"1590105848",
			"waver version: v0.12.4-rc5 from commit 5b1a61f9b58 built on 1590105848",
			true,
		}, {
			"v0.12.4-rc5",
			"5b1a61f9b58",
			"1590105848",
			"5b1a61f9b58",
			false,
		},
	}

	// save the current global variables so they can be set back after testing
	oldVal := version
	oldCommit := commit
	oldDate := date

	for _, test := range tests {
		// run through each test, should not be run in parallel.
		version = test.version
		commit = test.commit
		date = test.date

		// build the new Cobra command and configure stdout and args
		cmd := NewVersionCmd()
		b := bytes.NewBufferString("")
		cmd.SetOut(b)
		if test.verboseOutput {
			cmd.SetArgs([]string{"version"})
		} else {
			cmd.SetArgs([]string{"version", "--commit"})
		}

		// Run the cobra command similar to how an end user would
		err := cmd.Execute()
		assert.Nil(t, err)

		// assert output string matches expectations
		out, err := ioutil.ReadAll(b)
		assert.Nil(t, err)
		assert.Equal(t, test.expect, string(out))
	}

	// put the original build values back after tests have run
	version = oldVal
	commit = oldCommit
	date = oldDate
}
