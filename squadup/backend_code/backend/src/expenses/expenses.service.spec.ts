import { Test, TestingModule } from '@nestjs/testing';
import { ExpensesService } from './expenses.service';
import { SupabaseService } from '../supabase/supabase.service';
import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';

describe('ExpensesService', () => {
  let service: ExpensesService;
  let supabaseService: SupabaseService;

  const mockSupabaseService = {
    client: {
      from: jest.fn(() => ({
        select: jest.fn(() => ({
          eq: jest.fn(() => ({
            single: jest.fn(),
            eq: jest.fn(() => ({
              single: jest.fn(),
            })),
          })),
        })),
        insert: jest.fn(() => ({
          select: jest.fn(() => ({
            single: jest.fn(),
          })),
        })),
        update: jest.fn(() => ({
          eq: jest.fn(() => ({
            eq: jest.fn(),
          })),
        })),
        delete: jest.fn(() => ({
          eq: jest.fn(),
        })),
      })),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ExpensesService,
        {
          provide: SupabaseService,
          useValue: mockSupabaseService,
        },
      ],
    }).compile();

    service = module.get<ExpensesService>(ExpensesService);
    supabaseService = module.get<SupabaseService>(SupabaseService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('validateGroupMembership', () => {
    it('should throw ForbiddenException if user is not a member of the group', async () => {
      const mockClient = {
        from: jest.fn(() => ({
          select: jest.fn(() => ({
            eq: jest.fn(() => ({
              eq: jest.fn(() => ({
                single: jest.fn().mockResolvedValue({ data: null, error: 'Not found' }),
              })),
            })),
          })),
        })),
      };

      supabaseService.client = mockClient;

      await expect(
        service['validateGroupMembership']('group-id', 'user-id')
      ).rejects.toThrow(ForbiddenException);
    });
  });

  // Add more tests as needed
});