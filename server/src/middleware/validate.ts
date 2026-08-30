import { Request, Response, NextFunction, RequestHandler } from 'express';
import { Schema } from 'joi';
import ApiError from '../common/apiError';

export const validate = (schema: Schema, property: 'body' | 'query' | 'params' = 'body'): RequestHandler => {
  return (req: Request, _res: Response, next: NextFunction) => {
    const { error, value } = schema.validate(req[property], {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const errorMessage = error.details.map((detail) => detail.message).join(', ');
      return next(new ApiError(400, errorMessage));
    }

    req[property] = value;
    next();
  };
};

export default validate;
