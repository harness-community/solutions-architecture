package pipeline
import future.keywords.if
import future.keywords.in

verifications := {
  "SNOW TICKET": "CHG\\d{6}"
}

mandatory_keys := [
  "SNOW TICKET"
]

deny[msg] {
  some key, value in input[0].outcome.approverInputs
  has_key(verifications, key)

  not regex.match(verifications[key], value)

  msg := sprintf("The value (%s) of input (%s) does not match the support pattern (%s)",[value, key, verifications[key]])
}

deny[msg] {
  approverInputs = object.keys(input[0].outcome.approverInputs)
  some key in mandatory_keys

  not array_contains(approverInputs, key)

  msg := sprintf("The following input (%s) has not been configured",[key])
}

array_contains(arr, elem) {
	arr[_] = elem
}

has_key(x, k) if {
	_ = x[k]
}
