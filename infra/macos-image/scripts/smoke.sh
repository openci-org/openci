#!/bin/bash
set -euo pipefail

# Use the same non-login environment as firebase/functions/executor/model.ts.
export FLUTTER_ROOT="$HOME/fvm/default"
export PATH="$FLUTTER_ROOT/bin:$HOME/.pub-cache/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
work=$(mktemp -d /tmp/openci-image-smoke.XXXXXX)
trap 'rm -rf "$work"' EXIT
cd "$work"
flutter create --platforms=android,ios,macos --project-name image_smoke flutter_app
cd flutter_app
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter build apk --release
flutter build ios --release --no-codesign

mkdir "$work/go"
cd "$work/go"
go mod init example.com/openci/image-smoke
cat > main.go <<'GO'
package main

import "fmt"

func add(a, b int) int { return a + b }
func main() { fmt.Println(add(20, 22)) }
GO
cat > main_test.go <<'GO'
package main

import "testing"

func TestAdd(t *testing.T) {
	if add(20, 22) != 42 {
		t.Fatal("unexpected result")
	}
}
GO
gofmt -w main.go main_test.go
go vet ./...
go test ./...
go build -o image-smoke .
[[ $(./image-smoke) == 42 ]]
echo OPENCI_IMAGE_BUILD_VERIFIED
