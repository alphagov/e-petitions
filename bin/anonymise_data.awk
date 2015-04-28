BEGIN {
  OFS=","
  FS=","
}

/,\ / {
  gsub(/, /, " ")
}
/INSERT INTO `petitions/ {
  if (NF == 20) {
    print $1, "\47petition"NR" name\47", "\47petition"NR" description. This is a placeholder petition description created in order to make the data anonymous.\47", $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20
  }
  next
}

/INSERT INTO `signatures/ {
  if (NF == 13) {
    print $1, "\47name"NR"\47", "\47email"NR"@example.com\47", $4, $5, "\47sw1a 1aa\47", $7, "\47 0.0.0.0\47", $9, $10, $11, $12, $13
  }
  next
}
//
