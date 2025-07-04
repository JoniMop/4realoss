// Copyright 2014 The Gogs Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

package route

import (
	"github.com/go-macaron/binding"
	"gopkg.in/macaron.v1"

	"gogs.io/gogs/internal/context"
	"gogs.io/gogs/internal/form"
	"gogs.io/gogs/internal/route/user"
)

// RegisterRoutes registers all routes
func RegisterRoutes(m *macaron.Macaron) {
	reqSignOut := context.Toggle(&context.ToggleOptions{SignOutRequired: true})
	bindIgnErr := binding.BindIgnErr

	// User routes
	m.Group("/user", func() {
		m.Group("/login", func() {
			m.Combo("").Get(user.Login).
				Post(bindIgnErr(form.SignIn{}), user.LoginPost)
			m.Combo("/two_factor").Get(user.LoginTwoFactor).
				Post(user.LoginTwoFactorPost)
			m.Combo("/two_factor_recovery_code").Get(user.LoginTwoFactorRecoveryCode).
				Post(user.LoginTwoFactorRecoveryCodePost)
			m.Post("/metamask", user.LoginMetamask)
		})

		m.Get("/sign_up", user.SignUp)
		m.Post("/sign_up", bindIgnErr(form.Register{}), user.SignUpPost)
		m.Get("/reset_password", user.ResetPasswd)
		m.Post("/reset_password", user.ResetPasswdPost)
	}, reqSignOut)
}
