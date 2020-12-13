package version

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

// TestGetVersion will validate the output string
// when build with various flags. This command must not be
// run in parallel as there are global options which are
// configured during normal builds using ldflags.
func TestGetVersion(t *testing.T) {
	tests := []struct {
		version     string
		commit      string
		date        string
		expect      string
		shortOutput bool
	}{
		{
			"a",
			"b",
			"c",
			"waver version: a from commit b built on c",
			false,
		}, {
			"v0.12.4",
			"5b1a61f9b58e3778986c99b1282840ce64329614",
			"Thu May 21 16:48:18 PDT 2020",
			"waver version: v0.12.4 from commit 5b1a61f9b58e3778986c99b1282840ce64329614 built on Thu May 21 16:48:18 PDT 2020",
			false,
		}, {
			"v0.12.4-rc5",
			"5b1a61f9b58",
			"1590105848",
			"waver version: v0.12.4-rc5 from commit 5b1a61f9b58 built on 1590105848",
			false,
		}, {
			"v0.12.4-rc5",
			"5b1a61f9b58",
			"1590105848",
			"5b1a61f9b58",
			true,
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
		v := Get(test.shortOutput)

		// assert output string matches expectations
		assert.Equal(t, test.expect, v)
	}

	// put the original build values back after tests have run
	version = oldVal
	commit = oldCommit
	date = oldDate
}
