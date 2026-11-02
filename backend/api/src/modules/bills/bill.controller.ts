import { All, Controller, Header, HttpException, UseGuards } from '@nestjs/common';
import { AuthGuard } from '../auth/auth.guard';

/** BE-P3-001: bills are now `remind` recurring rules. Every old route answers 410. */
@Controller('v1/bills')
@UseGuards(AuthGuard)
export class BillController {
  @All() @Header('Cache-Control', 'no-store')
  gone(): never {
    throw gone();
  }

  @All('*path') @Header('Cache-Control', 'no-store')
  goneNested(): never {
    throw gone();
  }
}

function gone(): HttpException {
  return new HttpException({
    error: {
      code: 'BILL_GONE',
      message: 'Bills moved to /api/v1/recurring-transactions with mode=remind',
      details: [],
    },
  }, 410);
}
