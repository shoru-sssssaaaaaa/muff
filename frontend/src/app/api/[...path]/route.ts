import { NextRequest, NextResponse } from "next/server";

const BACKEND_URL = process.env.BACKEND_URL ?? "http://localhost:8080";

async function proxyRequest(request: NextRequest) {
  const { pathname, search } = request.nextUrl;
  const backendPath = pathname.replace(/^\/api/, "");
  const url = `${BACKEND_URL}${backendPath}${search}`;

  const headers = new Headers(request.headers);
  headers.delete("host");

  const res = await fetch(url, {
    method: request.method,
    headers,
    body: request.body,
    // @ts-expect-error -- Node.js fetch supports duplex for streaming request bodies
    duplex: "half",
  });

  return new NextResponse(res.body, {
    status: res.status,
    headers: res.headers,
  });
}

export const GET = proxyRequest;
export const POST = proxyRequest;
export const PUT = proxyRequest;
export const DELETE = proxyRequest;
export const PATCH = proxyRequest;
