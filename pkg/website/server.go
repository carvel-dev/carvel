// Copyright 2020 VMware, Inc.
// SPDX-License-Identifier: Apache-2.0

package website

import (
	"fmt"
	"log"
	"net"
	"net/http"
	"strings"
	"time"
)

const projectSiteDomain = "carvel.dev"
const k14sDomain = "k14s.io"

type ServerOpts struct {
	ListenAddr string
	ErrorFunc  func(error) ([]byte, error)
}

type Server struct {
	opts ServerOpts
}

func NewServer(opts ServerOpts) *Server {
	return &Server{opts}
}

func (s *Server) Mux() *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("/", s.redirectToSubprojects(s.redirectToProjectSite(s.redirectToHTTPs(s.noCacheHandler(s.mainHandler)))))
	mux.HandleFunc("/community", s.redirectToProjectSite(s.redirectToHTTPs(s.noCacheHandler(s.communityHandler))))
	mux.HandleFunc("/blog", s.redirectToProjectSite(s.redirectToHTTPs(s.noCacheHandler(s.blogHandler))))
	mux.HandleFunc("/js/", s.redirectToHTTPs(s.noCacheHandler(s.assetHandler)))
	mux.HandleFunc("/health", s.healthHandler)
	mux.HandleFunc("/install.sh", s.redirectToHTTPs(s.noCacheHandler(s.install)))
	return mux
}

func (s *Server) Run() error {
	server := &http.Server{
		Addr:    s.opts.ListenAddr,
		Handler: s.Mux(),
	}
	fmt.Printf("Listening on http://%s\n", server.Addr)
	return server.ListenAndServe()
}

func (s *Server) mainHandler(w http.ResponseWriter, r *http.Request) {
	s.write(w, []byte(Files["templates/index.html"].Content))
}

func (s *Server) communityHandler(w http.ResponseWriter, r *http.Request) {
	s.write(w, []byte(Files["templates/community.html"].Content))
}

func (s *Server) blogHandler(w http.ResponseWriter, r *http.Request) {
	s.write(w, []byte(Files["templates/blog.html"].Content))
}

func (s *Server) assetHandler(w http.ResponseWriter, r *http.Request) {
	if strings.HasSuffix(r.URL.Path, ".css") {
		w.Header().Set("Content-Type", "text/css")
	}
	if strings.HasSuffix(r.URL.Path, ".js") {
		w.Header().Set("Content-Type", "application/javascript")
	}
	s.write(w, []byte(Files[strings.TrimPrefix(r.URL.Path, "/")].Content))
}

func (s *Server) healthHandler(w http.ResponseWriter, r *http.Request) {
	s.write(w, []byte("ok"))
}

func (s *Server) install(w http.ResponseWriter, r *http.Request) {
	s.write(w, []byte(Files["templates/install.sh"].Content))
}

func (s *Server) logError(w http.ResponseWriter, err error) {
	log.Print(err.Error())

	resp, err := s.opts.ErrorFunc(err)
	if err != nil {
		fmt.Fprintf(w, "generation error: %s", err.Error())
		return
	}

	s.write(w, resp)
}

func (s *Server) write(w http.ResponseWriter, data []byte) {
	w.Write(data) // not fmt.Fprintf!
}

func (s *Server) redirectToHTTPs(wrappedFunc func(http.ResponseWriter, *http.Request)) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		checkHTTPs := true
		clientIP, _, err := net.SplitHostPort(r.RemoteAddr)
		if err == nil {
			if clientIP == "127.0.0.1" {
				checkHTTPs = false
			}
		}

		if checkHTTPs && r.Header.Get(http.CanonicalHeaderKey("x-forwarded-proto")) != "https" {
			if r.Method == http.MethodGet || r.Method == http.MethodHead {
				host := r.Header.Get("host")
				if len(host) == 0 {
					s.logError(w, fmt.Errorf("expected non-empty Host header"))
					return
				}

				http.Redirect(w, r, "https://"+host, http.StatusMovedPermanently)
				return
			}

			// Fail if it's not a GET or HEAD since req may have carried body insecurely
			s.logError(w, fmt.Errorf("expected HTTPs connection"))
			return
		}

		wrappedFunc(w, r)
	}
}
func (s *Server) redirectToProjectSite(wrappedFunc func(http.ResponseWriter, *http.Request)) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		host := r.Header.Get("host")
		url := r.URL.RequestURI()
		if strings.Contains(host, k14sDomain) {
			http.Redirect(w, r, "https://"+projectSiteDomain+url, http.StatusMovedPermanently)
			return
		}

		wrappedFunc(w, r)
	}
}

var (
	subprojectsHostMappings = map[string]string{
		"ytt.k14s.io":     "get-ytt.io",
		"kbld.k14s.io":    "get-kbld.io",
		"kapp.k14s.io":    "get-kapp.io",
		"kwt.k14s.io":     "github.com/k14s/kwt",
		"ytt.carvel.dev":  "get-ytt.io",
		"kbld.carvel.dev": "get-kbld.io",
		"kapp.carvel.dev": "get-kapp.io",
		"kwt.carvel.dev":  "github.com/k14s/kwt",
	}
)

func (s *Server) redirectToSubprojects(wrappedFunc func(http.ResponseWriter, *http.Request)) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet || r.Method == http.MethodHead {
			host := r.Header.Get("host")
			if len(host) > 0 {
				if hostMapping, found := subprojectsHostMappings[host]; found {
					http.Redirect(w, r, "https://"+hostMapping, http.StatusMovedPermanently)
					return
				}
			}
		}

		wrappedFunc(w, r)
	}
}

var (
	noCacheHeaders = map[string]string{
		"Expires":         time.Unix(0, 0).Format(time.RFC1123),
		"Cache-Control":   "no-cache, private, max-age=0",
		"Pragma":          "no-cache",
		"X-Accel-Expires": "0",
	}
)

func (s *Server) noCacheHandler(wrappedFunc func(http.ResponseWriter, *http.Request)) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		for k, v := range noCacheHeaders {
			w.Header().Set(k, v)
		}

		wrappedFunc(w, r)
	}
}
