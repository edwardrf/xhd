-- Oversimplifed kalman filter for single IR sensor
-- Copied from:
-- http://greg.czerniak.info/node/5g.czerniak.info/node/5
require "class"

Kalman = class(function(kal, q, r)
		kal.current_state_estimate = 0
		kal.current_prob_estimate = 0
		kal.Q = q or 0.1
		kal.R = r or 15
	end)

function Kalman:step(control_vector, measurement_vector)
	local predicted_state_estimate = self.current_state_estimate + control_vector
	local predicted_prob_estimate = self.current_prob_estimate + self.Q
	local innovation = measurement_vector - predicted_state_estimate
	local innovation_covariance = predicted_prob_estimate + self.R
	local kalman_gain = predicted_prob_estimate / innovation_covariance
	self.current_state_estimate = predicted_state_estimate + kalman_gain * innovation
	self.current_prob_estimate = (1 - kalman_gain) * predicted_prob_estimate
	return self.current_state_estimate
end
