package cmd

import (
	"github.com/cppforlife/cobrautil"
	"github.com/spf13/cobra"
)

type K14sIoOptions struct{}

func NewK14sIoOptions() *K14sIoOptions {
	return &K14sIoOptions{}
}

func NewDefaultK14sIoCmd() *cobra.Command {
	return NewK14sIoCmd(NewK14sIoOptions())
}

func NewK14sIoCmd(o *K14sIoOptions) *cobra.Command {
	cmd := NewWebsiteCmd(NewWebsiteOptions())

	cmd.Use = "k14s.io"
	cmd.Short = "shows k14s.io website (used for development)"

	// Affects children as well
	cmd.SilenceErrors = true
	cmd.SilenceUsage = true

	// Disable docs header
	cmd.DisableAutoGenTag = true

	// Last one runs first
	cobrautil.VisitCommands(cmd, cobrautil.ReconfigureCmdWithSubcmd)
	cobrautil.VisitCommands(cmd, cobrautil.ReconfigureLeafCmd)
	cobrautil.VisitCommands(cmd, cobrautil.WrapRunEForCmd(cobrautil.ResolveFlagsForCmd))

	return cmd
}
