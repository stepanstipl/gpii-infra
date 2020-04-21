variable "locust_target_app" {
  default = ""
}

variable "locust_target_host" {
  default = ""
}

variable "locust_script" {
  default = ""
}

variable "locust_swarm_duration" {
  default = 30
}

variable "locust_workers" {
  default = 3
}

variable "locust_users" {
  default = 50
}

variable "locust_hatch_rate" {
  default = 15
}

variable "locust_desired_total_rps" {
  default = 20
}

variable "locust_desired_median_response_time" {
  default = 100
}

variable "locust_desired_max_response_time" {
  default = 500
}

variable "locust_desired_num_failures" {
  default = 0
}

variable "locust_wait_for_target" {
  default = "true"
}

variable "locust_worker_target_labels_app" {
  default = ""
}
