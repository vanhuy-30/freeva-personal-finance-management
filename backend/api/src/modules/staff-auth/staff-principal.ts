import type { Request } from 'express';

export type StaffPrincipal = {
  id: string;
  role: 'staff';
};

export type StaffRequest = Request & {
  staff: StaffPrincipal;
};
