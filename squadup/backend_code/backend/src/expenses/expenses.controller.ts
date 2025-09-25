import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { ExpensesService } from './expenses.service';
import { CreateExpenseDto } from './dto/create-expense.dto';
import { UpdateExpenseDto } from './dto/update-expense.dto';
import { FilterExpensesDto } from './dto/filter-expenses.dto';

@Controller('expenses')
@UseGuards(AuthGuard)
export class ExpensesController {
  constructor(private readonly expensesService: ExpensesService) { }

  @Post()
  async createExpense(@Body() createExpenseDto: CreateExpenseDto, @CurrentUser() userId: string) {
    return this.expensesService.createExpense(createExpenseDto, userId);
  }

  @Get('group/:groupId')
  async getExpensesByGroup(
    @Param('groupId') groupId: string,
    @CurrentUser() userId: string,
    @Query() filters: FilterExpensesDto,
  ) {
    return this.expensesService.getExpensesByGroup(groupId, userId, filters);
  }

  @Get(':id')
  async getExpenseById(@Param('id') id: string, @CurrentUser() userId: string) {
    return this.expensesService.getExpenseById(id, userId);
  }

  @Put(':id')
  async updateExpense(
    @Param('id') id: string,
    @Body() updateExpenseDto: UpdateExpenseDto,
    @CurrentUser() userId: string,
  ) {
    return this.expensesService.updateExpense(id, updateExpenseDto, userId);
  }

  @Delete(':id')
  async deleteExpense(@Param('id') id: string, @CurrentUser() userId: string) {
    await this.expensesService.deleteExpense(id, userId);
    return { message: 'Despesa deletada com sucesso' };
  }
}