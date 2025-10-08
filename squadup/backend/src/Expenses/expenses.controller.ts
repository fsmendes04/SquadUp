import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '../User/user.guard';
import { CurrentUser } from '../User/current-user.decorator';
import { ExpensesService } from './expenses.service';
import { CreateExpenseDto } from './dto/create-expense.dto';
import { UpdateExpenseDto } from './dto/update-expense.dto';
import { FilterExpensesDto } from './dto/filter-expenses.dto';

@Controller('expenses')
@UseGuards(AuthGuard)
export class ExpensesController {
  constructor(private readonly expensesService: ExpensesService) { }

  @Post()
  async createExpense(@Body() createExpenseDto: CreateExpenseDto, @CurrentUser() user: any) {
    return this.expensesService.createExpense(createExpenseDto, user.id);
  }

  @Get('group/:groupId')
  async getExpensesByGroup(
    @Param('groupId') groupId: string,
    @CurrentUser() user: any,
    @Query() filters: FilterExpensesDto,
  ) {
    return this.expensesService.getExpensesByGroup(groupId, user.id, filters);
  }

  @Get(':id')
  async getExpenseById(@Param('id') id: string, @CurrentUser() user: any) {
    return this.expensesService.getExpenseById(id, user.id);
  }

  @Put(':id')
  async updateExpense(
    @Param('id') id: string,
    @Body() updateExpenseDto: UpdateExpenseDto,
    @CurrentUser() user: any,
  ) {
    return this.expensesService.updateExpense(id, updateExpenseDto, user.id);
  }

  @Delete(':id')
  async deleteExpense(@Param('id') id: string, @CurrentUser() user: any) {
    await this.expensesService.deleteExpense(id, user.id);
    return { message: 'Despesa deletada com sucesso' };
  }
}