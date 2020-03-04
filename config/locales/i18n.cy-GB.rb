{
  "cy-GB": {
    "i18n": {
      "plural": {
        "keys": %i[zero one two other],
        "rule": -> (count) {
          case count
          when 0
            :zero
          when 1
            :one
          when 2
            :two
          else
            :other
          end
        }
      }
    }
  }
}
