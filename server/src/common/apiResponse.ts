import { Response } from 'express';

export class ApiResponse {
  static success<T>(res: Response, data: T = null as unknown as T, message = 'Success', statusCode = 200): Response {
    return res.status(statusCode).json({
      success: true,
      message,
      data,
    });
  }

  static error(res: Response, message = 'Error', statusCode = 500, errors: unknown = null): Response {
    return res.status(statusCode).json({
      success: false,
      message,
      errors,
    });
  }
}

export default ApiResponse;
