expectupdates {
expect << EOF
  spawn yay -Syu
  expect_background -ex "Proceed with installation" {send "y\n"}
  interact
EOF
}
