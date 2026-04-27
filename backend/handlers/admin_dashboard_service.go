package handlers

import (
	"regexp"
	"strings"
)

// CleanLogDetail removes database IDs and status flags from activity strings
func CleanLogDetail(raw string) string {
	if raw == "" {
		return ""
	}

	// Define your patterns (Go uses ` values for raw strings)
	reID := regexp.MustCompile(`\s*\(id=\d+\)`)
	reStatus := regexp.MustCompile(`\s*\(active=\w+(?:,\s*archived=\w+)?\)`)
	reArchived := regexp.MustCompile(`\s*\(archived=\w+\)`)
	reEmail := regexp.MustCompile(`:\s*[\w.+-]+@[\w.-]+\.\w+`)
	reMultiSpace := regexp.MustCompile(`\s{2,}`)

	// Apply replacements
	clean := reID.ReplaceAllString(raw, "")
	clean = reStatus.ReplaceAllString(clean, "")
	clean = reArchived.ReplaceAllString(clean, "")
	clean = reEmail.ReplaceAllString(clean, "")
	clean = reMultiSpace.ReplaceAllString(clean, " ")

	return strings.TrimSpace(clean)
}