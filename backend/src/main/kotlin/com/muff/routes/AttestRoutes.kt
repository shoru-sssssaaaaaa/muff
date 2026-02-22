package com.muff.routes

import com.muff.model.AttestChallengeResponse
import com.muff.model.AttestVerifyRequest
import com.muff.model.AttestVerifyResponse
import com.muff.model.ErrorResponse
import com.muff.service.AppAttestService
import io.ktor.http.HttpStatusCode
import io.ktor.server.request.receive
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import io.ktor.server.routing.post
import io.ktor.server.routing.route
import java.util.Base64

fun Route.attestRoutes(attestService: AppAttestService) {
    route("/v1/attest") {
        get("/challenge") {
            val challenge = attestService.generateChallenge()
            call.respond(AttestChallengeResponse(challenge = challenge))
        }

        post("/verify") {
            val request = call.receive<AttestVerifyRequest>()

            if (request.keyId.isBlank() || request.attestation.isBlank() || request.challenge.isBlank()) {
                call.respond(
                    HttpStatusCode.BadRequest,
                    ErrorResponse("bad_request", "Missing required fields"),
                )
                return@post
            }

            val attestationBytes = try {
                Base64.getDecoder().decode(request.attestation)
            } catch (e: IllegalArgumentException) {
                call.respond(
                    HttpStatusCode.BadRequest,
                    ErrorResponse("bad_request", "Invalid base64 attestation"),
                )
                return@post
            }

            val verified = attestService.verifyAttestation(
                keyId = request.keyId,
                attestationBytes = attestationBytes,
                challenge = request.challenge,
            )

            if (verified) {
                call.respond(AttestVerifyResponse(verified = true))
            } else {
                call.respond(
                    HttpStatusCode.Forbidden,
                    AttestVerifyResponse(verified = false),
                )
            }
        }
    }
}
