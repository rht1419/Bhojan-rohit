export function successResponse<T>(data: T, message?: string) {
  return { success: true, data, ...(message && { message }) };
}

export function errorResponse(code: string, message: string, details?: unknown[]) {
  return {
    success: false,
    error: { code, message, ...(details?.length && { details }) },
  };
}
