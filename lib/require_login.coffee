define ->
  (req, res, next) ->
    if req.session and req.session.passport and req.session.passport.user
      next()
    else
      res.send(403)
