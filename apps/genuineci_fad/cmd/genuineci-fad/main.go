package main

import (
	"context"
	"errors"
	"fmt"
	"os"

	"github.com/urfave/cli/v3"
)

func main() {
	cmd := &cli.Command{
		Name:        "genuineci-fad",
		Usage:       "Firebase App Distribution CLI",
		Description: "Upload support is not implemented yet.",
		Commands: []*cli.Command{
			{
				Name:        "upload",
				Usage:       "Upload an IPA to Firebase App Distribution",
				Description: "Upload support is not implemented yet.",
				Flags: []cli.Flag{
					&cli.StringFlag{
						Name:     "ipa",
						Usage:    "Path to the IPA file",
						Required: true,
					},
					&cli.StringFlag{
						Name:     "app-id",
						Usage:    "Firebase App ID",
						Required: true,
					},
				},
				Action: func(context.Context, *cli.Command) error {
					return errors.New("upload is not implemented yet")
				},
			},
		},
	}

	if err := cmd.Run(context.Background(), os.Args); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
