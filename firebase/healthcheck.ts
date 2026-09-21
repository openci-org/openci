fetch("http://127.0.0.1:9099/emulator/v1/projects/demo-openci/config")
  .then((response) => {
    if (response.ok) {
      process.exit(0);
    } else {
      process.exit(1);
    }
  })
  .catch(() => {
    process.exit(1);
  });
