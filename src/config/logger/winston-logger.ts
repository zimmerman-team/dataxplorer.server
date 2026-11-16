import winston from 'winston';
const {combine, timestamp, prettyPrint, printf} = winston.format;

// Both loggers write their file and stdout. Docker keeps stdout, which is where
// the central log agent collects the server's logs.
export const winstonLogger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: combine(
    timestamp({format: 'YYYY-MM-DD HH:mm:ss'}),
    prettyPrint(),
    printf(
      info =>
        `${info.timestamp} [${info.level.toUpperCase()}]: ${info.message} ${
          info.stack ? info.stack : ''
        }`,
    ),
  ),
  transports: [
    new winston.transports.File({
      filename: './logging/dx_server.log',
      level: 'info',
      maxsize: 1000000, // 1MB
    }),
    new winston.transports.Console(),
  ],
});

export const frontendLogger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: combine(
    timestamp({format: 'YYYY-MM-DD HH:mm:ss'}),
    prettyPrint(),
    printf(
      info =>
        `${info.timestamp} [${info.level.toUpperCase()}]: ${info.message} ${
          info.stack ? info.stack : ''
        }`,
    ),
  ),
  transports: [
    new winston.transports.File({
      filename: './logging/dx_client.log',
      level: 'info',
    }),
    // These come from the browser but share the server's stdout: mark them.
    new winston.transports.Console({
      format: printf(
        info =>
          `${info.timestamp} [${info.level.toUpperCase()}] [client]: ${
            info.message
          } ${info.stack ? info.stack : ''}`,
      ),
    }),
  ],
});
