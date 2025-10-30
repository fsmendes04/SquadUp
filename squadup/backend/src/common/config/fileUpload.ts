import { diskStorage } from 'multer';
import { BadRequestException } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import * as path from 'path';

export const multerConfig = {
  storage: diskStorage({
    destination: './uploads/temp',
    filename: (req, file, cb) => {
      const uniqueName = `${uuidv4()}${path.extname(file.originalname)}`;
      cb(null, uniqueName);
    },
  }),
  fileFilter: (req, file, cb) => {
    const allowedMimes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new BadRequestException('Invalid file type. Only JPEG, JPG, PNG, and WEBP are allowed.'), false);
    }
  },
  limits: {
    fileSize: 5 * 1024 * 1024,
    files: 1,
  },
};
