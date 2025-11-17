import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  HttpException,
  HttpStatus,
  Logger,
  BadRequestException
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { AuthGuard } from '../User/userToken';
import { CurrentUser, GetToken } from '../common/decorators';
import { ExpensesService } from './expensesService';
import { CreateExpenseDto } from './dto/create-expense.dto';
import { UpdateExpenseDto } from './dto/update-expense.dto';
import { FilterExpensesDto } from './dto/filter-expenses.dto';

@Controller('expenses')
@UseGuards(AuthGuard)
export class ExpensesController {
  private readonly logger = new Logger(ExpensesController.name);

  constructor(private readonly expensesService: ExpensesService) { }

  @Post()
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  async createExpense(
    @Body() createExpenseDto: CreateExpenseDto,
    @CurrentUser() user: any,
    @GetToken() token: string,
  ) {
    try {
      if (!createExpenseDto.group_id || !createExpenseDto.payer_id) {
        throw new BadRequestException('Group ID and Payer ID are required');
      }

      const expense = await this.expensesService.createExpense(createExpenseDto, user.id, token);

      return {
        success: true,
        message: 'Expense created successfully',
        data: expense,
      };
    } catch (error) {
      this.logger.error('Expense creation error', error.message);

      const statusCode = error.status || HttpStatus.BAD_REQUEST;
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to create expense',
        },
        statusCode,
      );
    }
  }

  @Get('group/:groupId')
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  async getExpensesByGroup(
    @Param('groupId') groupId: string,
    @CurrentUser() user: any,
    @Query() filters: FilterExpensesDto,
    @GetToken() token: string,
  ) {
    try {
      const expenses = await this.expensesService.getExpensesByGroup(groupId, user.id, filters, token);

      return {
        success: true,
        message: 'Expenses retrieved successfully',
        data: expenses,
      };
    } catch (error) {
      this.logger.error('Error fetching expenses by group', error.message);

      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to fetch expenses',
        },
        error.status || HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Get(':id')
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  async getExpenseById(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @GetToken() token: string,
  ) {
    try {
      const expense = await this.expensesService.getExpenseById(id, user.id, token);

      return {
        success: true,
        message: 'Expense retrieved successfully',
        data: expense,
      };
    } catch (error) {
      this.logger.error('Error fetching expense', error.message);

      const statusCode = error.status || HttpStatus.BAD_REQUEST;
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to fetch expense',
        },
        statusCode,
      );
    }
  }

  @Put(':id')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  async updateExpense(
    @Param('id') id: string,
    @Body() updateExpenseDto: UpdateExpenseDto,
    @CurrentUser() user: any,
    @GetToken() token: string,
  ) {
    try {
      if (Object.keys(updateExpenseDto).length === 0) {
        throw new BadRequestException('At least one field must be provided for update');
      }

      const expense = await this.expensesService.updateExpense(id, updateExpenseDto, user.id, token);

      return {
        success: true,
        message: 'Expense updated successfully',
        data: expense,
      };
    } catch (error) {
      this.logger.error('Expense update error', error.message);

      const statusCode = error.status || HttpStatus.BAD_REQUEST;
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to update expense',
        },
        statusCode,
      );
    }
  }

  @Delete(':id')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  async deleteExpense(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @GetToken() token: string,
  ) {
    try {
      await this.expensesService.deleteExpense(id, user.id, token);

      return {
        success: true,
        message: 'Expense deleted successfully',
      };
    } catch (error) {
      this.logger.error('Expense deletion error', error.message);

      const statusCode = error.status || HttpStatus.BAD_REQUEST;
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to delete expense',
        },
        statusCode,
      );
    }
  }
}