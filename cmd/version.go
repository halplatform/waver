/*
Copyright © 2020 Patrick Glass <patrickglass@gmail.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
package cmd

import (
	"fmt"

	"github.com/halplatform/waver/pkg/version"
	"github.com/rs/zerolog/log"
	"github.com/spf13/cobra"
)

// NewVersionCmd create a new Cobra version command
func NewVersionCmd() *cobra.Command {
	var cmd = &cobra.Command{
		Use:   "version",
		Short: "Display the binary version",
		Long:  ``,
		Run:   PrintVersion,
	}
	cmd.Flags().BoolP("commit", "", false, "Display only the git commit string.")
	return cmd
}

func init() {
	versionCmd := NewVersionCmd()
	rootCmd.AddCommand(versionCmd)
}

// PrintVersion will print the current binary version out
func PrintVersion(cmd *cobra.Command, args []string) {
	displayCommit, err := cmd.Flags().GetBool("commit")
	if err != nil {
		log.Error().Err(err).Msg("Could not understand --commit boolean flag.")
	}
	fmt.Fprintf(cmd.OutOrStdout(), version.Get(displayCommit))
}
