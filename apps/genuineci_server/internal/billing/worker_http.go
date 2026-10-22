package billing

import "net/http"

func (s *Service) handleWorkerClaim(w http.ResponseWriter, r *http.Request) {
	var request workerClaimRequest
	if !readBillingJSON(w, r, &request, false) {
		return
	}
	claim, err := s.claimJob(r.Context(), request)
	if err != nil {
		writeBillingError(w, err)
		return
	}
	writeBillingJSON(w, http.StatusOK, map[string]*workerClaim{"claim": claim})
}

func (s *Service) handleWorkerStart(w http.ResponseWriter, r *http.Request) {
	var request workerExecutionRequest
	if !readBillingJSON(w, r, &request, false) {
		return
	}
	result, err := s.startAdmittedExecution(r.Context(), request)
	writeWorkerExecution(w, result, err)
}

func (s *Service) handleWorkerReport(w http.ResponseWriter, r *http.Request) {
	var request workerExecutionRequest
	if !readBillingJSON(w, r, &request, false) {
		return
	}
	result, err := s.reportAdmittedExecution(r.Context(), request)
	writeWorkerExecution(w, result, err)
}

func writeWorkerExecution(w http.ResponseWriter, result *execution, err error) {
	if err != nil {
		writeBillingError(w, err)
		return
	}
	writeBillingJSON(w, http.StatusOK, map[string]bool{
		"active": result.FinishedAt == nil, "measurementIncomplete": result.MeasurementIncomplete,
	})
}
