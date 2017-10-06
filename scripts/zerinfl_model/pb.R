## parametric bootstrap
predict.zeroinfl <- function(object, newdata, type = c("response", "prob"),
                             se = FALSE, MC = 1000, level = .95,
                             na.action = na.pass,...) {
    type <- match.arg(type)

    ## if no new data supplied
    if(missing(newdata)){
        rval <- object$fitted.values
        if(!is.null(object$x)) {
            X <- object$x$count
            Z <- object$x$zero
        }
        else if(!is.null(object$model)) {
            X <- model.matrix(object$terms$count, object$model,
                              contrasts = object$contrasts$count)
            Z <- model.matrix(object$terms$zero,  object$model,
                              contrasts = object$contrasts$zero)
        }
        else {
            stop("no X and/or Z matrices can be extracted from fitted model")
        }

        if(type == "prob") {
            mu <- exp(X %*% object$coefficients$count)[,1]
            phi <- object$linkinv(Z %*% object$coefficients$zero)[,1]
        }
    }

    else {
        mf <- model.frame(delete.response(object$terms$full), newdata,
                          na.action = na.action, xlev = object$levels)
        X <- model.matrix(delete.response(object$terms$count), mf,
                          contrasts = object$contrasts$count)
        Z <- model.matrix(delete.response(object$terms$zero),  mf,
                          contrasts = object$contrasts$zero)
        mu <- exp(X %*% object$coefficients$count)[,1]
        phi <- object$linkinv(Z %*% object$coefficients$zero)[,1]
        rval <- (1-phi) * mu
    }

    if(se & !is.null(X) & !is.null(Z)){
        require(mvtnorm)
        vc <- -solve(object$optim$hessian)
        kx <- length(object$coefficients$count)
        kz <- length(object$coefficients$zero)
        parms <- object$optim$par

        if (type!="prob") {
            yhat.sim <- matrix(NA, MC, dim(X)[1])
            for(i in 1 : MC) {
                cat(paste("MC iterate", i, "of", MC, "\n"))
                parms.sim <- rmvnorm(n=1,mean=parms,sigma=vc)
                beta <- parms.sim[1:kx]
                gamma <- parms.sim[(kx+1):(kx+kz)]
                mu.sim <- exp(X%*%beta)[,1]
                phi.sim <- object$linkinv(Z%*%gamma)[,1]
                yhat.sim[i,] <- (1-phi.sim)*mu.sim
            }
        }

        out <- list()
        out$lower <- apply(yhat.sim,2,quantile,(1-level)/2)
        out$upper <- apply(yhat.sim,2,quantile,1-((1-level)/2))
        out$se <- apply(yhat.sim,2,sd)
    }

    ## predicted probabilities
    if(type == "prob") {
        if(!is.null(object$y)) y <- object$y
        else if(!is.null(object$model)) y <- model.response(object$model)
        else stop("predicted probabilities cannot be computed for fits with
                  y = FALSE and model = FALSE")

        yUnique <- min(y):max(y)
        nUnique <- length(yUnique)
        rval <- matrix(NA, nrow = length(rval), ncol = nUnique)
        dimnames(rval) <- list(rownames(X), yUnique)

        switch(object$dist,
               "poisson" = {
                   rval[, 1] <- phi + (1-phi) * exp(-mu)
                   for(i in 2:nUnique) rval[,i] <- (1-phi) * dpois(yUnique[i], lambda = mu)
               },

               "negbin" = {
                   theta <- object$theta
                   rval[, 1] <- phi + (1-phi) * dnbinom(0, mu = mu, size = theta)
                   for(i in 2:nUnique) rval[,i] <- (1-phi) * dnbinom(yUnique[i], mu = mu, size = theta)

               },

               "geometric" = {
                   rval[, 1] <- phi + (1-phi) * dnbinom(0, mu = mu, size = 1)
                   for(i in 2:nUnique) rval[,i] <- (1-phi) * dnbinom(yUnique[i], mu = mu, size = 1)
               })
    }

    if(se)
        rval <- list(rval,out)
    rval

}